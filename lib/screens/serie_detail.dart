import 'package:flutter/material.dart';

import '../app_state.dart';
import '../export.dart';
import '../formato.dart';
import '../models.dart';
import '../stats.dart';
import '../widgets/comunes.dart';
import '../widgets/grafico.dart';
import 'serie_dialog.dart';

class SerieDetailScreen extends StatelessWidget {
  const SerieDetailScreen({super.key, required this.serieId});

  final int serieId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final serie = estado.serieById(serieId);
        if (serie == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Este control ya no existe.')),
          );
        }
        final r = ResumenSerie(serie, estado.tomasDe(serieId));
        return Scaffold(
          appBar: AppBar(
            title: Text(serie.nombre),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: 'Exportar Excel',
                onPressed: () async {
                  try {
                    await exportarSerie(serie, r.tomas);
                  } catch (e) {
                    if (context.mounted) mostrarMensaje(context, 'Error: $e');
                  }
                },
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'editar') {
                    await mostrarSerieDialog(context, serie: serie);
                  } else if (v == 'borrar') {
                    final ok = await confirmar(context, 'Borrar control',
                        'Se borra el control, pero las tomas quedan guardadas sin control asignado.');
                    if (!ok) return;
                    await estado.borrarSerie(serieId);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'borrar', child: Text('Borrar')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Principal(r: r),
              const SizedBox(height: 12),
              _TablaResumen(r: r),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Promedio por día', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Builder(builder: (_) {
                        final porDia = r.promedioPorDia;
                        return GraficoPresion(
                          etiquetas: [for (var i = 1; i <= porDia.length; i++) 'D$i'],
                          sis: [for (final d in porDia) d.sis],
                          dia: [for (final d in porDia) d.dia],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Planilla', style: Theme.of(context).textTheme.titleMedium),
              for (final dia in r.diasPlanilla) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Text(
                    'Día $dia · ${fDiaLargo(serie.fechaDelDia(dia))}${dia == 1 ? ' (no cuenta en el promedio)' : ''}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Card(
                  child: (r.porDia[dia] ?? const []).isEmpty
                      ? const ListTile(title: Text('Sin tomas'))
                      : Column(
                          children: [
                            for (final t in r.porDia[dia]!) TomaTile(toma: t),
                          ],
                        ),
                ),
              ],
              if (serie.notas != null) ...[
                const SizedBox(height: 12),
                Card(child: ListTile(title: const Text('Notas'), subtitle: Text(serie.notas!))),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Principal extends StatelessWidget {
  const _Principal({required this.r});

  final ResumenSerie r;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final p = r.principal;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Promedio (sin día 1)', style: tt.titleSmall),
            const SizedBox(height: 4),
            Text(p.texto, style: tt.displaySmall),
            Text(
              [
                if (p.pulso != null) 'Pulso ${fNum(p.pulso)}',
                '${p.n} tomas',
                '${r.diasConDatos} de ${Serie.dias} días',
              ].join(' · '),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablaResumen extends StatelessWidget {
  const _TablaResumen({required this.r});

  final ResumenSerie r;

  @override
  Widget build(BuildContext context) {
    final filas = <(String, Resumen)>[
      ('Todas las tomas', r.todas),
      ('Mañana', r.manana),
      ('Tarde', r.tarde),
      ('Pre med', r.preMed),
      ('Post med', r.postMed),
    ];
    const bold = TextStyle(fontWeight: FontWeight.w600);
    Widget celda(String t, {TextStyle? style, TextAlign align = TextAlign.right}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(t, style: style, textAlign: align),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(2)},
          children: [
            TableRow(children: [
              celda('', align: TextAlign.left),
              celda('Presión', style: bold),
              celda('Pulso', style: bold),
              celda('Tomas', style: bold),
            ]),
            for (final (nombre, res) in filas)
              TableRow(children: [
                celda(nombre, align: TextAlign.left),
                celda(res.texto),
                celda(fNum(res.pulso)),
                celda('${res.n}'),
              ]),
          ],
        ),
      ),
    );
  }
}
