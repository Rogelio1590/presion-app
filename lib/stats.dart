import 'dart:math';

import 'models.dart';

/// Promedios de un conjunto de tomas.
class Resumen {
  const Resumen(this.n, this.sis, this.dia, this.pulso);

  final int n;
  final double? sis;
  final double? dia;
  final double? pulso;

  static Resumen de(Iterable<Toma> tomas) {
    var n = 0, s = 0, d = 0, pn = 0, ps = 0;
    for (final t in tomas) {
      n++;
      s += t.sistolica;
      d += t.diastolica;
      if (t.pulso != null) {
        pn++;
        ps += t.pulso!;
      }
    }
    if (n == 0) return const Resumen(0, null, null, null);
    return Resumen(n, s / n, d / n, pn == 0 ? null : ps / pn);
  }

  /// "134/84"
  String get texto => n == 0 ? '—' : '${sis!.round()}/${dia!.round()}';

  /// "134/84 p82"
  String get textoCompleto =>
      n == 0 ? '—' : '$texto${pulso != null ? ' p${pulso!.round()}' : ''}';
}

/// Estadísticas de un control de 7 días. Siguiendo el protocolo,
/// el promedio principal descarta el primer día de mediciones.
class ResumenSerie {
  ResumenSerie(this.serie, List<Toma> tomas)
      : tomas = [...tomas]..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

  final Serie serie;
  final List<Toma> tomas;

  late final List<Toma> sinDia1 =
      tomas.where((t) => serie.diaDe(t.fechaHora) != 1).toList();

  Resumen get principal => Resumen.de(sinDia1);
  Resumen get todas => Resumen.de(tomas);
  Resumen get manana => Resumen.de(sinDia1.where((t) => t.turno == Turno.manana));
  Resumen get tarde => Resumen.de(sinDia1.where((t) => t.turno == Turno.tarde));
  Resumen get preMed => Resumen.de(sinDia1.where((t) => t.med == 'pre'));
  Resumen get postMed => Resumen.de(sinDia1.where((t) => t.med == 'post'));

  late final Map<int, List<Toma>> porDia = () {
    final m = <int, List<Toma>>{};
    for (final t in tomas) {
      m.putIfAbsent(serie.diaDe(t.fechaHora), () => []).add(t);
    }
    return m;
  }();

  /// Días a mostrar en la planilla: 1..7 más cualquier día fuera de rango con datos.
  List<int> get diasPlanilla =>
      ({for (var d = 1; d <= Serie.dias; d++) d, ...porDia.keys}.toList()..sort());

  int get diasConDatos => porDia.keys.where((d) => d >= 1 && d <= Serie.dias).length;

  /// Promedio por día (1..7) para el gráfico.
  List<Resumen> get promedioPorDia => [
        for (var d = 1; d <= max(Serie.dias, porDia.keys.fold(0, max)); d++)
          Resumen.de(porDia[d] ?? const []),
      ];
}
