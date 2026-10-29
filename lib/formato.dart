import 'package:intl/intl.dart';

final fDia = DateFormat('dd/MM/yyyy');
final fDiaCorto = DateFormat('dd/MM');
final fHora = DateFormat('HH:mm');

String capitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Martes 7 de octubre"
String fDiaLargo(DateTime d) =>
    capitalizar(DateFormat("EEEE d 'de' MMMM", 'es').format(d));

/// "Octubre 2026"
String fMesAnio(DateTime d) =>
    capitalizar(DateFormat('MMMM yyyy', 'es').format(d));

String fNum(double? v) => v == null ? '—' : v.round().toString();

/// Diferencia B − A redondeada, con signo.
String fDif(double? a, double? b) {
  if (a == null || b == null) return '—';
  final d = (b - a).round();
  if (d > 0) return '+$d';
  if (d < 0) return '−${-d}';
  return '0';
}
