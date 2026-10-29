import 'package:flutter/material.dart';

import '../app_state.dart';
import '../formato.dart';
import '../models.dart';
import '../stats.dart';
import '../widgets/comunes.dart';
import '../widgets/grafico.dart';

/// Un período a comparar: un control completo o un rango de fechas libre.
class Periodo {
  const Periodo.control(Serie this.serie) : rango = null;
  const Periodo.fechas(DateTimeRange this.rango) : serie = null;

  final Serie? serie;
  final DateTimeRange? rango;

  String get etiqueta => serie != null
      ? serie!.nombre
      : '${fDiaCorto.format(rango!.start)} – ${fDia.format(rango!.end)}';

  String get aclaracion =>
      serie != null ? 'Control (sin día 1)' : 'Rango de fechas (todas las tomas)';

  Resumen resumen(AppState app) {
    if (serie != null) {
      return ResumenSerie(serie!, app.tomasDe(serie!.id!)).principal;
    }
    final desde = soloFecha(rango!.start);
    final hasta = soloFecha(rango!.end).add(const Duration(days: 1));
    return Resumen.de(app.tomas.where(
        (t) => !t.fechaHora.isBefore(desde) && t.fechaHora.isBefore(hasta)));
  }

  /// Vuelve a buscar el control por si fue editado o borrado.
  Periodo? refrescar(AppState app) {
    if (serie == null) return this;
    final s = app.serieById(serie!.id);
    return s == null ? null : Periodo.control(s);
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Periodo? _a;
  Periodo? _b;

  Future<Periodo?> _elegirPeriodo() async {
    final eleccion = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Elegir rango de fechas…'),
              onTap: () => Navigator.pop(ctx, 'rango'),
            ),
            const Divider(),
            for (final s in estado.series)
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: Text(s.nombre),
                subtitle: Text('${fDiaCorto.format(s.inicio)} – ${fDia.format(s.fin)}'),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (eleccion is Serie) return Periodo.control(eleccion);
    if (eleccion == 'rango' && mounted) {
      final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (r != null) return Periodo.fechas(r);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [MenuGeneral()],
      ),
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          final series = estado.series;
          final a = _a?.refrescar(estado) ??
              (series.length >= 2 ? Periodo.control(series[1]) : null);
          final b = _b?.refrescar(estado) ??
              (series.isNotEmpty ? Periodo.control(series[0]) : null);
          final tt = Theme.of(context).textTheme;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProximoControl(),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Evolución de los controles', style: tt.titleMedium),
                      Text('Promedio de cada control, sin el día 1', style: tt.bodySmall),
                      const SizedBox(height: 8),
                      _Evolucion(series: series),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comparar', style: tt.titleMedium),
                      Text('Elegí dos controles o dos rangos de fechas', style: tt.bodySmall),
                      const SizedBox(height: 12),
                      _SelectorPeriodo(
                        letra: 'A',
                        periodo: a,
                        onTap: () async {
                          final p = await _elegirPeriodo();
                          if (p != null) setState(() => _a = p);
                        },
                      ),
                      const SizedBox(height: 8),
                      _SelectorPeriodo(
                        letra: 'B',
                        periodo: b,
                        onTap: () async {
                          final p = await _elegirPeriodo();
                          if (p != null) setState(() => _b = p);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (a != null && b != null)
                        _TablaComparacion(ra: a.resumen(estado), rb: b.resumen(estado))
                      else
                        const Text('Necesitás al menos dos períodos para comparar.'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProximoControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activa = estado.serieActiva;
    final proximo = estado.proximoControl;
    final hoy = soloFecha(DateTime.now());
    final String texto;
    final IconData icono;
    if (activa != null) {
      texto = 'Control en curso: ${activa.nombre} (día ${activa.diaDe(hoy)} de ${Serie.dias})';
      icono = Icons.play_circle_outline;
    } else if (proximo == null) {
      texto = 'Todavía no hay controles cargados.';
      icono = Icons.info_outline;
    } else if (proximo.isAfter(hoy)) {
      final dias = diasEntre(hoy, proximo);
      texto = 'Próximo control: ${fDia.format(proximo)} (en $dias días)';
      icono = Icons.event;
    } else {
      texto = 'Ya corresponde el próximo control (desde el ${fDia.format(proximo)}).';
      icono = Icons.notification_important_outlined;
    }
    return Card(
      child: ListTile(leading: Icon(icono), title: Text(texto)),
    );
  }
}

class _Evolucion extends StatelessWidget {
  const _Evolucion({required this.series});

  final List<Serie> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Cuando tengas controles cargados vas a ver la evolución acá.'),
      );
    }
    final cronologico = series.reversed.toList();
    final resumenes = [
      for (final s in cronologico) ResumenSerie(s, estado.tomasDe(s.id!)).principal,
    ];
    return Column(
      children: [
        GraficoPresion(
          etiquetas: [for (final s in cronologico) fDiaCorto.format(s.inicio)],
          sis: [for (final r in resumenes) r.sis],
          dia: [for (final r in resumenes) r.dia],
        ),
        const SizedBox(height: 8),
        for (var i = cronologico.length - 1; i >= 0; i--)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(cronologico[i].nombre),
            subtitle: Text(fDia.format(cronologico[i].inicio)),
            trailing: Text(
              resumenes[i].textoCompleto,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
      ],
    );
  }
}

class _SelectorPeriodo extends StatelessWidget {
  const _SelectorPeriodo({required this.letra, required this.periodo, required this.onTap});

  final String letra;
  final Periodo? periodo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 14, child: Text(letra)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(periodo?.etiqueta ?? 'Elegir…'),
                if (periodo != null)
                  Text(periodo!.aclaracion, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _TablaComparacion extends StatelessWidget {
  const _TablaComparacion({required this.ra, required this.rb});

  final Resumen ra;
  final Resumen rb;

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(fontWeight: FontWeight.w600);
    Widget celda(String t, {TextStyle? style, TextAlign align = TextAlign.right}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(t, style: style, textAlign: align),
        );
    TableRow fila(String nombre, double? a, double? b) => TableRow(children: [
          celda(nombre, align: TextAlign.left),
          celda(fNum(a)),
          celda(fNum(b)),
          celda(fDif(a, b), style: bold),
        ]);
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.6)},
      border: TableBorder(
        horizontalInside: BorderSide(color: Theme.of(context).dividerColor),
      ),
      children: [
        TableRow(children: [
          celda(''),
          celda('A', style: bold),
          celda('B', style: bold),
          celda('B − A', style: bold),
        ]),
        fila('Sistólica', ra.sis, rb.sis),
        fila('Diastólica', ra.dia, rb.dia),
        fila('Pulso', ra.pulso, rb.pulso),
        TableRow(children: [
          celda('Tomas', align: TextAlign.left),
          celda('${ra.n}'),
          celda('${rb.n}'),
          celda(''),
        ]),
      ],
    );
  }
}
