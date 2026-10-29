import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../formato.dart';
import '../models.dart';
import '../widgets/comunes.dart';
import 'serie_dialog.dart';

class RegistroScreen extends StatelessWidget {
  const RegistroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presión'),
        actions: const [MenuGeneral()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirToma(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva toma'),
      ),
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          if (!estado.cargado) {
            return const Center(child: CircularProgressIndicator());
          }
          final grupos = <DateTime, List<Toma>>{};
          for (final t in estado.tomas) {
            grupos.putIfAbsent(soloFecha(t.fechaHora), () => []).add(t);
          }
          final activa = estado.serieActiva;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              activa != null ? _ControlEnCurso(serie: activa) : const _SinControl(),
              const SizedBox(height: 16),
              if (estado.tomas.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Todavía no cargaste tomas.\nTocá "Nueva toma" para empezar.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final e in grupos.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Text(fDiaLargo(e.key),
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Card(
                  child: Column(
                    children: [for (final t in e.value) TomaTile(toma: t)],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ControlEnCurso extends StatelessWidget {
  const _ControlEnCurso({required this.serie});

  final Serie serie;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final tomas = estado.tomasDe(serie.id!);
    final deHoy = tomas.where((t) => mismoDia(t.fechaHora, hoy));
    final m = deHoy.where((t) => t.turno == Turno.manana).length;
    final t = deHoy.where((t) => t.turno == Turno.tarde).length;
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serie.nombre, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Día ${serie.diaDe(hoy)} de ${Serie.dias} · ${fDiaCorto.format(serie.inicio)} al ${fDiaCorto.format(serie.fin)}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ChipTurno(texto: 'Mañana', hechas: m),
                const SizedBox(width: 8),
                _ChipTurno(texto: 'Tarde', hechas: t),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: min(1, tomas.length / Serie.tomasEsperadas),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 4),
            Text('${tomas.length} de ${Serie.tomasEsperadas} tomas del control',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ChipTurno extends StatelessWidget {
  const _ChipTurno({required this.texto, required this.hechas});

  final String texto;
  final int hechas;

  @override
  Widget build(BuildContext context) {
    final completo = hechas >= 2;
    return Chip(
      avatar: Icon(completo ? Icons.check_circle : Icons.radio_button_unchecked, size: 18),
      label: Text('$texto ${min(hechas, 2)}/2'),
    );
  }
}

class _SinControl extends StatelessWidget {
  const _SinControl();

  @override
  Widget build(BuildContext context) {
    final proximo = estado.proximoControl;
    final hoy = soloFecha(DateTime.now());
    String? aviso;
    if (proximo != null) {
      aviso = proximo.isAfter(hoy)
          ? 'Próximo control sugerido: ${fDia.format(proximo)}'
          : 'Ya corresponde el próximo control (desde el ${fDia.format(proximo)}).';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No hay un control en curso',
                style: Theme.of(context).textTheme.titleMedium),
            if (aviso != null) ...[
              const SizedBox(height: 4),
              Text(aviso),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => mostrarSerieDialog(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar control de 7 días'),
            ),
          ],
        ),
      ),
    );
  }
}
