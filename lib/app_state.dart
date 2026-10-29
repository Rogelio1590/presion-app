import 'package:flutter/foundation.dart';

import 'db.dart';
import 'models.dart';

/// Estado de la app: todas las series y tomas en memoria (son pocos datos).
class AppState extends ChangeNotifier {
  List<Serie> series = []; // más reciente primero
  List<Toma> tomas = []; // más reciente primero
  bool cargado = false;

  Future<void> cargar() async {
    series = await Db.instance.series();
    tomas = await Db.instance.tomas();
    cargado = true;
    notifyListeners();
  }

  Serie? serieById(int? id) {
    if (id == null) return null;
    for (final s in series) {
      if (s.id == id) return s;
    }
    return null;
  }

  Serie? serieParaFecha(DateTime f) {
    for (final s in series) {
      if (s.contiene(f)) return s;
    }
    return null;
  }

  Serie? get serieActiva => serieParaFecha(DateTime.now());

  List<Toma> tomasDe(int serieId) =>
      tomas.where((t) => t.serieId == serieId).toList()
        ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

  /// Los controles se repiten cada 3 meses.
  DateTime? get proximoControl {
    if (series.isEmpty) return null;
    final ultimo = series.first.inicio;
    return DateTime(ultimo.year, ultimo.month + 3, ultimo.day);
  }

  Future<void> guardarToma(Toma t) async {
    await Db.instance.guardarToma(t);
    await cargar();
  }

  Future<void> borrarToma(int id) async {
    await Db.instance.borrarToma(id);
    await cargar();
  }

  /// Guarda el control y le asigna las tomas sueltas que caen en sus fechas.
  Future<Serie> guardarSerie(Serie s) async {
    final id = await Db.instance.guardarSerie(s);
    final guardada =
        Serie(id: id, nombre: s.nombre, inicio: s.inicio, notas: s.notas);
    for (final t in tomas) {
      if (t.serieId == null && guardada.contiene(t.fechaHora)) {
        await Db.instance.asignarSerie(t.id!, id);
      }
    }
    await cargar();
    return guardada;
  }

  Future<void> borrarSerie(int id) async {
    await Db.instance.borrarSerie(id);
    await cargar();
  }
}

final estado = AppState();
