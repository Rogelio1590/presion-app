/// Modelos de datos: controles de 7 días (Serie) y tomas de presión (Toma).
library;

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// Días calendario entre dos fechas (ignora la hora).
int diasEntre(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fechaIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Un control de automonitoreo: 7 días, 2 tomas a la mañana y 2 a la tarde.
class Serie {
  const Serie({this.id, required this.nombre, required this.inicio, this.notas});

  static const int dias = 7;
  static const int tomasPorDia = 4;
  static const int tomasEsperadas = dias * tomasPorDia;

  final int? id;
  final String nombre;
  final DateTime inicio;
  final String? notas;

  DateTime get fin => DateTime(inicio.year, inicio.month, inicio.day + dias - 1);

  DateTime fechaDelDia(int dia) =>
      DateTime(inicio.year, inicio.month, inicio.day + dia - 1);

  /// Número de día dentro del control (1 = primer día).
  int diaDe(DateTime fecha) => diasEntre(inicio, fecha) + 1;

  bool contiene(DateTime fecha) {
    final d = diaDe(fecha);
    return d >= 1 && d <= dias;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'nombre': nombre,
        'inicio': _fechaIso(inicio),
        'notas': notas,
      };

  factory Serie.fromMap(Map<String, Object?> m) => Serie(
        id: m['id'] as int,
        nombre: m['nombre'] as String,
        inicio: DateTime.parse(m['inicio'] as String),
        notas: m['notas'] as String?,
      );
}

enum Turno { manana, tarde }

extension TurnoTexto on Turno {
  String get etiqueta => this == Turno.manana ? 'Mañana' : 'Tarde';
  String get codigo => this == Turno.manana ? 'M' : 'T';
}

class Toma {
  const Toma({
    this.id,
    this.serieId,
    required this.fechaHora,
    required this.sistolica,
    required this.diastolica,
    this.pulso,
    required this.turno,
    this.med,
    this.comentario,
  });

  final int? id;
  final int? serieId;
  final DateTime fechaHora;
  final int sistolica;
  final int diastolica;
  final int? pulso;
  final Turno turno;

  /// 'pre', 'post' o null.
  final String? med;
  final String? comentario;

  /// Antes de las 15 h se considera toma de la mañana.
  static Turno turnoSugerido(DateTime f) =>
      f.hour < 15 ? Turno.manana : Turno.tarde;

  String get presionTexto =>
      '$sistolica/$diastolica${pulso != null ? ' p$pulso' : ''}';

  String? get medTexto => switch (med) {
        'pre' => 'pre med',
        'post' => 'post med',
        _ => null,
      };

  Map<String, Object?> toMap() => {
        'id': id,
        'serie_id': serieId,
        'fecha_hora': fechaHora.toIso8601String(),
        'sistolica': sistolica,
        'diastolica': diastolica,
        'pulso': pulso,
        'turno': turno.codigo,
        'med': med,
        'comentario': comentario,
      };

  factory Toma.fromMap(Map<String, Object?> m) => Toma(
        id: m['id'] as int,
        serieId: m['serie_id'] as int?,
        fechaHora: DateTime.parse(m['fecha_hora'] as String),
        sistolica: m['sistolica'] as int,
        diastolica: m['diastolica'] as int,
        pulso: m['pulso'] as int?,
        turno: m['turno'] == 'T' ? Turno.tarde : Turno.manana,
        med: m['med'] as String?,
        comentario: m['comentario'] as String?,
      );
}
