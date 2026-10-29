import 'package:flutter/material.dart';

import '../app_state.dart';
import '../formato.dart';
import '../models.dart';
import '../stats.dart';
import '../widgets/comunes.dart';
import 'serie_detail.dart';
import 'serie_dialog.dart';

class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controles'),
        actions: const [MenuGeneral()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarSerieDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo control'),
      ),
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          if (estado.series.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Cada control son 7 días de tomas (2 a la mañana y 2 a la tarde).\n'
                  'Creá uno para empezar.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final s in estado.series) _SerieCard(serie: s),
            ],
          );
        },
      ),
    );
  }
}

class _SerieCard extends StatelessWidget {
  const _SerieCard({required this.serie});

  final Serie serie;

  @override
  Widget build(BuildContext context) {
    final r = ResumenSerie(serie, estado.tomasDe(serie.id!));
    final tt = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SerieDetailScreen(serieId: serie.id!)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serie.nombre, style: tt.titleMedium),
                    const SizedBox(height: 2),
                    Text('${fDiaCorto.format(serie.inicio)} – ${fDia.format(serie.fin)}'),
                    Text('${r.tomas.length}/${Serie.tomasEsperadas} tomas · ${r.diasConDatos} días',
                        style: tt.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(r.principal.texto, style: tt.headlineSmall),
                  Text(
                    r.principal.pulso == null
                        ? 'prom. sin día 1'
                        : 'pulso ${fNum(r.principal.pulso)} · sin día 1',
                    style: tt.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
