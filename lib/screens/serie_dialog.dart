import 'package:flutter/material.dart';

import '../app_state.dart';
import '../formato.dart';
import '../models.dart';

/// Crear o editar un control de 7 días.
Future<Serie?> mostrarSerieDialog(BuildContext context, {Serie? serie}) {
  final hoy = soloFecha(DateTime.now());
  final nombre = TextEditingController(text: serie?.nombre ?? 'Control ${fMesAnio(hoy)}');
  final notas = TextEditingController(text: serie?.notas ?? '');
  var inicio = serie?.inicio ?? hoy;

  return showDialog<Serie>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(serie == null ? 'Nuevo control de 7 días' : 'Editar control'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Primer día'),
                subtitle: Text(
                    '${fDia.format(inicio)} → ${fDia.format(DateTime(inicio.year, inicio.month, inicio.day + Serie.dias - 1))}'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: inicio,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(hoy.year + 1),
                  );
                  if (d != null) setState(() => inicio = d);
                },
              ),
              TextField(
                controller: notas,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                maxLines: 2,
                minLines: 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final s = Serie(
                id: serie?.id,
                nombre: nombre.text.trim().isEmpty ? 'Control ${fMesAnio(inicio)}' : nombre.text.trim(),
                inicio: soloFecha(inicio),
                notas: notas.text.trim().isEmpty ? null : notas.text.trim(),
              );
              final guardada = await estado.guardarSerie(s);
              if (ctx.mounted) Navigator.pop(ctx, guardada);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}
