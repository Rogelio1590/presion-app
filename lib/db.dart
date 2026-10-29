import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Base SQLite local. Todo queda guardado solo en el celular.
class Db {
  Db._();
  static final Db instance = Db._();

  Database? _db;

  Future<String> rutaArchivo() async =>
      p.join(await getDatabasesPath(), 'presion.db');

  Future<Database> get _database async => _db ??= await _abrir();

  Future<Database> _abrir() async => openDatabase(
        await rutaArchivo(),
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE series(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre TEXT NOT NULL,
              inicio TEXT NOT NULL,
              notas TEXT
            )''');
          await db.execute('''
            CREATE TABLE tomas(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              serie_id INTEGER REFERENCES series(id) ON DELETE SET NULL,
              fecha_hora TEXT NOT NULL,
              sistolica INTEGER NOT NULL,
              diastolica INTEGER NOT NULL,
              pulso INTEGER,
              turno TEXT NOT NULL,
              med TEXT,
              comentario TEXT
            )''');
          await db.execute('CREATE INDEX idx_tomas_fecha ON tomas(fecha_hora)');
          await db.execute('CREATE INDEX idx_tomas_serie ON tomas(serie_id)');
        },
      );

  Future<List<Serie>> series() async {
    final db = await _database;
    final rows = await db.query('series', orderBy: 'inicio DESC, id DESC');
    return rows.map(Serie.fromMap).toList();
  }

  Future<List<Toma>> tomas() async {
    final db = await _database;
    final rows = await db.query('tomas', orderBy: 'fecha_hora DESC, id DESC');
    return rows.map(Toma.fromMap).toList();
  }

  Future<int> guardarSerie(Serie s) async {
    final db = await _database;
    final m = s.toMap()..remove('id');
    if (s.id == null) return db.insert('series', m);
    await db.update('series', m, where: 'id = ?', whereArgs: [s.id]);
    return s.id!;
  }

  /// Las tomas del control no se borran: quedan sin control asignado.
  Future<void> borrarSerie(int id) async {
    final db = await _database;
    await db.delete('series', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> guardarToma(Toma t) async {
    final db = await _database;
    final m = t.toMap()..remove('id');
    if (t.id == null) return db.insert('tomas', m);
    await db.update('tomas', m, where: 'id = ?', whereArgs: [t.id]);
    return t.id!;
  }

  Future<void> asignarSerie(int tomaId, int serieId) async {
    final db = await _database;
    await db.update('tomas', {'serie_id': serieId},
        where: 'id = ?', whereArgs: [tomaId]);
  }

  Future<void> borrarToma(int id) async {
    final db = await _database;
    await db.delete('tomas', where: 'id = ?', whereArgs: [id]);
  }

  /// Copia el archivo de la base a [destino]. Cierra la conexión antes
  /// para que la copia quede consistente; se reabre sola en el próximo uso.
  Future<File> copiaDeSeguridad(String destino) async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    return File(await rutaArchivo()).copy(destino);
  }
}
