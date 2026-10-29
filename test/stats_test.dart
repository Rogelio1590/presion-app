import 'package:flutter_test/flutter_test.dart';
import 'package:presion_app/models.dart';
import 'package:presion_app/stats.dart';

Toma _t(DateTime f, int s, int d, int? p) => Toma(
      fechaHora: f,
      sistolica: s,
      diastolica: d,
      pulso: p,
      turno: Toma.turnoSugerido(f),
    );

void main() {
  test('turno sugerido según la hora', () {
    expect(Toma.turnoSugerido(DateTime(2026, 10, 7, 9, 58)), Turno.manana);
    expect(Toma.turnoSugerido(DateTime(2026, 10, 7, 21, 14)), Turno.tarde);
  });

  test('el promedio principal descarta el día 1', () {
    final serie = Serie(id: 1, nombre: 'Control', inicio: DateTime(2026, 10, 7));
    final tomas = [
      _t(DateTime(2026, 10, 7, 9, 58), 200, 120, 90), // día 1: no cuenta
      _t(DateTime(2026, 10, 8, 9, 2), 140, 88, 76),
      _t(DateTime(2026, 10, 8, 21, 37), 130, 80, null),
    ];
    final r = ResumenSerie(serie, tomas);
    expect(r.principal.n, 2);
    expect(r.principal.sis, 135);
    expect(r.principal.dia, 84);
    expect(r.principal.pulso, 76);
    expect(r.todas.n, 3);
    expect(r.diasConDatos, 2);
    expect(serie.diaDe(DateTime(2026, 10, 13)), 7);
    expect(serie.contiene(DateTime(2026, 10, 14)), isFalse);
  });

  test('textos', () {
    const r = Resumen(2, 134.6, 84.2, 81.5);
    expect(r.texto, '135/84');
    expect(r.textoCompleto, '135/84 p82');
  });
}
