import 'package:flutter/material.dart';

import '../app_state.dart';
import '../export.dart';
import '../formato.dart';
import '../models.dart';
import '../screens/toma_form.dart';

Future<bool> confirmar(BuildContext context, String titulo, String mensaje,
    {String accion = 'Borrar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(accion)),
      ],
    ),
  );
  return r ?? false;
}

void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

Future<void> abrirToma(BuildContext context, [Toma? toma]) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TomaFormScreen(toma: toma)),
  );
}

/// Fila de una toma en las listas.
class TomaTile extends StatelessWidget {
  const TomaTile({super.key, required this.toma, this.mostrarFecha = false});

  final Toma toma;
  final bool mostrarFecha;

  @override
  Widget build(BuildContext context) {
    final detalle = [
      mostrarFecha
          ? '${fDiaCorto.format(toma.fechaHora)} ${fHora.format(toma.fechaHora)}'
          : fHora.format(toma.fechaHora),
      toma.turno.etiqueta,
      toma.medTexto,
    ].whereType<String>().join(' · ');
    return ListTile(
      leading: CircleAvatar(child: Text(toma.turno.codigo)),
      title: Text(
        toma.presionTexto,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
      ),
      subtitle: Text(
        toma.comentario == null ? detalle : '$detalle\n${toma.comentario}',
      ),
      isThreeLine: toma.comentario != null,
      onTap: () => abrirToma(context, toma),
    );
  }
}

/// Menú común: exportar historial, backup y protocolo.
class MenuGeneral extends StatelessWidget {
  const MenuGeneral({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) async {
        try {
          switch (v) {
            case 'historial':
              if (estado.tomas.isEmpty) {
                mostrarMensaje(context, 'Todavía no hay tomas para exportar.');
                return;
              }
              await exportarHistorial(estado.series, estado.tomas, estado.serieById);
            case 'backup':
              await compartirBackup();
            case 'protocolo':
              await mostrarProtocolo(context);
          }
        } catch (e) {
          if (context.mounted) mostrarMensaje(context, 'Error: $e');
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'historial',
          child: ListTile(leading: Icon(Icons.table_view), title: Text('Exportar historial (Excel)')),
        ),
        PopupMenuItem(
          value: 'backup',
          child: ListTile(leading: Icon(Icons.backup), title: Text('Backup de la base')),
        ),
        PopupMenuItem(
          value: 'protocolo',
          child: ListTile(leading: Icon(Icons.info_outline), title: Text('Instrucciones del automonitoreo')),
        ),
      ],
    );
  }
}

Future<void> mostrarProtocolo(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Automonitoreo'),
      content: const SingleChildScrollView(
        child: Text(
          'Esquema\n'
          '• Al menos 4 días de mediciones, idealmente 7.\n'
          '• 2 mediciones a la mañana (antes del desayuno y de la medicación, '
          'con la vejiga vacía) y 2 a la tarde (antes de la cena), '
          'con 1–2 minutos de diferencia.\n'
          '• Registrar inmediatamente los resultados.\n\n'
          'Resultados\n'
          '• Se considera el promedio de todas las lecturas, descartando el '
          'primer día de mediciones.\n'
          '• Valor de referencia del consenso: 135/85 mmHg.\n\n'
          'Fuente: Consenso Argentino de Hipertensión Arterial (2018). '
          'La interpretación de los resultados la hace tu médico.',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
      ],
    ),
  );
}
