// Genera capturas de pantalla y un Excel de ejemplo con los datos de la
// planilla de octubre 2026. Se corre en GitHub Actions (workflow "Capturas"):
//   flutter test capturas/capturas_test.dart --update-goldens
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:presion_app/app_state.dart';
import 'package:presion_app/export.dart';
import 'package:presion_app/main.dart';
import 'package:presion_app/models.dart';
import 'package:presion_app/screens/dashboard_screen.dart';
import 'package:presion_app/screens/serie_detail.dart';

const _dpr = 2.625;

String _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  // flutter_tester vive en <root>/bin/cache/artifacts/engine/<plataforma>/
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 5; i++) {
    dir = dir.parent;
  }
  return dir.path;
}

Future<ByteData> _leer(File f) async => ByteData.view(Uint8List.fromList(await f.readAsBytes()).buffer);

Future<void> _cargarFuentes() async {
  final dir = Directory('${_flutterRoot()}/bin/cache/artifacts/material_fonts');
  final roboto = FontLoader('Roboto');
  for (final f in dir.listSync().whereType<File>()) {
    final nombre = f.uri.pathSegments.last;
    if (nombre.startsWith('Roboto-') && nombre.endsWith('.ttf')) {
      roboto.addFont(_leer(f));
    }
  }
  await roboto.load();
  final iconos = File('${dir.path}/MaterialIcons-Regular.otf');
  if (iconos.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(_leer(iconos))).load();
  }
}

/// Tomas de la planilla de automonitoreo (07/10 al 12/10/2026).
final _serie = Serie(id: 1, nombre: 'Control octubre 2026', inicio: DateTime(2026, 10, 7));

List<Toma> _tomasPlanilla() {
  var id = 0;
  Toma t(int dia, int h, int m, int s, int d, int p, [String? med]) {
    final f = DateTime(2026, 10, dia, h, m);
    return Toma(
      id: ++id,
      serieId: 1,
      fechaHora: f,
      sistolica: s,
      diastolica: d,
      pulso: p,
      turno: Toma.turnoSugerido(f),
      med: med,
    );
  }

  return [
    t(7, 9, 58, 133, 82, 82, 'pre'),
    t(7, 10, 0, 129, 81, 80, 'pre'),
    t(7, 21, 14, 143, 77, 91),
    t(7, 21, 16, 137, 83, 88),
    t(8, 9, 2, 139, 88, 76, 'pre'),
    t(8, 9, 4, 135, 79, 66, 'pre'),
    t(8, 21, 37, 152, 86, 84),
    t(8, 21, 39, 134, 86, 82),
    t(9, 8, 27, 128, 86, 77, 'pre'),
    t(9, 8, 29, 123, 85, 75, 'pre'),
    t(10, 10, 19, 127, 83, 77, 'pre'),
    t(10, 10, 21, 122, 83, 77, 'pre'),
    t(10, 21, 3, 142, 83, 86),
    t(10, 21, 5, 135, 82, 86),
    t(11, 9, 49, 121, 83, 74, 'pre'),
    t(11, 9, 52, 130, 86, 73, 'pre'),
    t(11, 21, 6, 151, 91, 94),
    t(11, 21, 8, 138, 86, 90),
    t(12, 11, 41, 135, 92, 76, 'post'),
    t(12, 11, 43, 119, 87, 77, 'post'),
    t(12, 20, 48, 147, 91, 94),
    t(12, 20, 50, 136, 88, 91),
  ];
}

Future<void> _captura(WidgetTester tester, Widget home, String nombre, double altoLogico) async {
  tester.view.devicePixelRatio = _dpr;
  tester.view.physicalSize = Size(1080, (altoLogico * _dpr).roundToDouble());
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PresionApp(home: home));
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$nombre.png'));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    Intl.defaultLocale = 'es';
    await _cargarFuentes();
    final tomas = _tomasPlanilla()..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    estado
      ..series = [_serie]
      ..tomas = tomas
      ..cargado = true;
  });

  test('Excel de ejemplo', () {
    final bytes = construirExcelSerie(_serie, estado.tomasDe(1)).encode()!;
    File('capturas/out/Presion_Control_octubre_2026.xlsx')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  });

  testWidgets('1 dashboard', (tester) async {
    await _captura(
      tester,
      DashboardScreen(
        periodoA: Periodo.fechas(DateTimeRange(start: DateTime(2026, 10, 8), end: DateTime(2026, 10, 9))),
        periodoB: Periodo.fechas(DateTimeRange(start: DateTime(2026, 10, 10), end: DateTime(2026, 10, 12))),
      ),
      '1_dashboard',
      1250,
    );
  });

  testWidgets('2 control detalle', (tester) async {
    await _captura(tester, const SerieDetailScreen(serieId: 1), '2_control_detalle', 2900);
  });

  testWidgets('3 controles', (tester) async {
    await _captura(tester, const Inicio(tabInicial: 1), '3_controles', 891);
  });

  testWidgets('4 registro', (tester) async {
    await _captura(tester, const Inicio(tabInicial: 0), '4_registro', 1500);
  });
}
