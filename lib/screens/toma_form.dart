import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../formato.dart';
import '../models.dart';
import '../widgets/comunes.dart';

class TomaFormScreen extends StatefulWidget {
  const TomaFormScreen({super.key, this.toma});

  final Toma? toma;

  @override
  State<TomaFormScreen> createState() => _TomaFormScreenState();
}

class _TomaFormScreenState extends State<TomaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sis = TextEditingController();
  final _dia = TextEditingController();
  final _pul = TextEditingController();
  final _com = TextEditingController();

  late DateTime _fecha;
  late Turno _turno;
  String _med = 'no'; // 'pre', 'post' o 'no'
  int? _serieId;
  bool _turnoManual = false;
  bool _serieManual = false;
  bool _guardando = false;

  bool get _editando => widget.toma != null;

  @override
  void initState() {
    super.initState();
    final t = widget.toma;
    if (t != null) {
      _fecha = t.fechaHora;
      _turno = t.turno;
      _med = t.med ?? 'no';
      _serieId = estado.serieById(t.serieId)?.id;
      _sis.text = '${t.sistolica}';
      _dia.text = '${t.diastolica}';
      _pul.text = t.pulso?.toString() ?? '';
      _com.text = t.comentario ?? '';
      _turnoManual = true;
      _serieManual = true;
    } else {
      final ahora = DateTime.now();
      _fecha = DateTime(ahora.year, ahora.month, ahora.day, ahora.hour, ahora.minute);
      _turno = Toma.turnoSugerido(_fecha);
      _med = _turno == Turno.manana ? 'pre' : 'no';
      _serieId = estado.serieParaFecha(_fecha)?.id;
    }
  }

  @override
  void dispose() {
    _sis.dispose();
    _dia.dispose();
    _pul.dispose();
    _com.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final h = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha),
    );
    if (!mounted) return;
    final hora = h ?? TimeOfDay.fromDateTime(_fecha);
    setState(() {
      _fecha = DateTime(d.year, d.month, d.day, hora.hour, hora.minute);
      if (!_turnoManual) _turno = Toma.turnoSugerido(_fecha);
      if (!_serieManual) _serieId = estado.serieParaFecha(_fecha)?.id;
    });
  }

  String? _validarRango(String? v, String nombre, int min, int max,
      {bool opcional = false}) {
    if (v == null || v.isEmpty) return opcional ? null : 'Requerido';
    final n = int.tryParse(v);
    if (n == null || n < min || n > max) return '$nombre: $min–$max';
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final sis = int.parse(_sis.text);
    final dia = int.parse(_dia.text);
    if (dia >= sis) {
      mostrarMensaje(context, 'La diastólica debería ser menor que la sistólica.');
      return;
    }
    setState(() => _guardando = true);
    final toma = Toma(
      id: widget.toma?.id,
      serieId: _serieId,
      fechaHora: _fecha,
      sistolica: sis,
      diastolica: dia,
      pulso: _pul.text.isEmpty ? null : int.parse(_pul.text),
      turno: _turno,
      med: _med == 'no' ? null : _med,
      comentario: _com.text.trim().isEmpty ? null : _com.text.trim(),
    );
    final primeraDelTurno = !_editando &&
        !estado.tomas.any((x) => mismoDia(x.fechaHora, _fecha) && x.turno == _turno);
    await estado.guardarToma(toma);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(primeraDelTurno
          ? 'Guardada. Hacé la segunda toma en 1–2 minutos.'
          : 'Toma guardada.'),
    ));
  }

  Future<void> _borrar() async {
    final ok = await confirmar(context, 'Borrar toma', '¿Seguro que querés borrar esta toma?');
    if (!ok || !mounted) return;
    await estado.borrarToma(widget.toma!.id!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final series = estado.series;
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        );
    final soloNumeros = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)];
    const grande = TextStyle(fontSize: 26, fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar toma' : 'Nueva toma'),
        actions: [
          if (_editando)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Borrar',
              onPressed: _borrar,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: Text(fDiaLargo(_fecha)),
                subtitle: Text(fHora.format(_fecha)),
                trailing: const Icon(Icons.edit),
                onTap: _elegirFecha,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sis,
                    autofocus: !_editando,
                    decoration: deco('Sistólica'),
                    style: grande,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: soloNumeros,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _validarRango(v, 'Sistólica', 60, 260),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _dia,
                    decoration: deco('Diastólica'),
                    style: grande,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: soloNumeros,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _validarRango(v, 'Diastólica', 30, 160),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _pul,
                    decoration: deco('Pulso'),
                    style: grande,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: soloNumeros,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        _validarRango(v, 'Pulso', 30, 220, opcional: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Turno', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SegmentedButton<Turno>(
              segments: const [
                ButtonSegment(value: Turno.manana, label: Text('Mañana'), icon: Icon(Icons.wb_sunny_outlined)),
                ButtonSegment(value: Turno.tarde, label: Text('Tarde'), icon: Icon(Icons.nights_stay_outlined)),
              ],
              selected: {_turno},
              onSelectionChanged: (s) => setState(() {
                _turno = s.first;
                _turnoManual = true;
              }),
            ),
            const SizedBox(height: 16),
            Text('Medicación', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'pre', label: Text('Pre med')),
                ButtonSegment(value: 'post', label: Text('Post med')),
                ButtonSegment(value: 'no', label: Text('—')),
              ],
              selected: {_med},
              onSelectionChanged: (s) => setState(() => _med = s.first),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int?>(
              value: _serieId,
              decoration: deco('Control'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Sin control')),
                for (final s in series)
                  DropdownMenuItem<int?>(
                    value: s.id,
                    child: Text('${s.nombre} (${fDiaCorto.format(s.inicio)})'),
                  ),
              ],
              onChanged: (v) => setState(() {
                _serieId = v;
                _serieManual = true;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _com,
              decoration: deco('Comentario (opcional)'),
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.check),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Guardar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
