import 'dart:io';
import 'dart:math';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'db.dart';
import 'formato.dart';
import 'models.dart';
import 'stats.dart';

const _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

final _borde = Border(borderStyle: BorderStyle.Thin);

CellStyle _estilo({
  bool bold = false,
  String? fondo,
  int? tamanio,
  HorizontalAlign h = HorizontalAlign.Left,
  bool bordes = true,
}) {
  if (fondo != null) {
    return CellStyle(
      bold: bold,
      fontSize: tamanio,
      backgroundColorHex: ExcelColor.fromHexString(fondo),
      horizontalAlign: h,
      verticalAlign: VerticalAlign.Center,
      leftBorder: bordes ? _borde : null,
      rightBorder: bordes ? _borde : null,
      topBorder: bordes ? _borde : null,
      bottomBorder: bordes ? _borde : null,
    );
  }
  return CellStyle(
    bold: bold,
    fontSize: tamanio,
    horizontalAlign: h,
    verticalAlign: VerticalAlign.Center,
    leftBorder: bordes ? _borde : null,
    rightBorder: bordes ? _borde : null,
    topBorder: bordes ? _borde : null,
    bottomBorder: bordes ? _borde : null,
  );
}

final _titulo = _estilo(bold: true, tamanio: 14, h: HorizontalAlign.Center, bordes: false);
final _subtitulo = _estilo(h: HorizontalAlign.Center, bordes: false);
final _encabezado = _estilo(bold: true, fondo: '#D9D9D9', h: HorizontalAlign.Center);
final _celdaDia = _estilo(bold: true, fondo: '#C9DAF8', h: HorizontalAlign.Center);
final _celdaTurno = _estilo(fondo: '#F3F3F3', h: HorizontalAlign.Center);
final _celda = _estilo();
final _etiqueta = _estilo(bold: true);

CellIndex _ix(int col, int fila) =>
    CellIndex.indexByColumnRow(columnIndex: col, rowIndex: fila);

void _set(Sheet sh, int col, int fila, CellValue? v, [CellStyle? st]) {
  final c = sh.cell(_ix(col, fila));
  c.value = v;
  if (st != null) c.cellStyle = st;
}

void _merge(Sheet sh, int c0, int f0, int c1, int f1, CellValue v, CellStyle st) {
  sh.merge(_ix(c0, f0), _ix(c1, f1), customValue: v);
  for (var f = f0; f <= f1; f++) {
    for (var c = c0; c <= c1; c++) {
      sh.cell(_ix(c, f)).cellStyle = st;
    }
  }
}

DoubleCellValue? _dec(double? v) =>
    v == null ? null : DoubleCellValue((v * 10).round() / 10);

String _nombreArchivo(String base) =>
    base.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_').replaceAll(RegExp(r'_+'), '_');

Excel _nuevoLibro(String primeraHoja) {
  final excel = Excel.createExcel();
  excel[primeraHoja];
  excel.setDefaultSheet(primeraHoja);
  if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');
  return excel;
}

Future<void> _compartir(Excel excel, String archivo, String asunto) async {
  final bytes = excel.encode();
  if (bytes == null) throw Exception('No se pudo generar el Excel');
  final dir = await getTemporaryDirectory();
  final f = File(p.join(dir.path, archivo));
  await f.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([XFile(f.path, mimeType: _xlsxMime)], subject: asunto);
}

/// Planilla de un control con el mismo formato que pide la cardióloga:
/// Día / Turno / Presión arterial / Hora, 2 tomas de mañana y 2 de tarde.
Future<void> exportarSerie(Serie serie, List<Toma> tomas) async {
  final r = ResumenSerie(serie, tomas);
  final excel = _nuevoLibro('Planilla');
  final sh = excel['Planilla'];

  var fila = 0;
  _merge(sh, 0, fila, 4, fila,
      TextCellValue('AUTOMONITOREO DE LA PRESIÓN ARTERIAL'), _titulo);
  fila++;
  _merge(
      sh,
      0,
      fila,
      4,
      fila,
      TextCellValue(
          '${serie.nombre} · del ${fDia.format(serie.inicio)} al ${fDia.format(serie.fin)}'),
      _subtitulo);
  fila += 2;

  const encabezados = ['Día', 'Turno', 'Presión arterial', 'Hora', 'Comentario'];
  for (var c = 0; c < encabezados.length; c++) {
    _set(sh, c, fila, TextCellValue(encabezados[c]), _encabezado);
  }
  fila++;

  for (final dia in r.diasPlanilla) {
    final delDia = r.porDia[dia] ?? const <Toma>[];
    final man = delDia.where((t) => t.turno == Turno.manana).toList();
    final tar = delDia.where((t) => t.turno == Turno.tarde).toList();
    final filas = <(Turno, Toma?)>[
      for (var i = 0; i < max(2, man.length); i++)
        (Turno.manana, i < man.length ? man[i] : null),
      for (var i = 0; i < max(2, tar.length); i++)
        (Turno.tarde, i < tar.length ? tar[i] : null),
    ];

    final inicio = fila;
    for (final (turno, toma) in filas) {
      _set(sh, 1, fila, TextCellValue(turno.etiqueta), _celdaTurno);
      _set(sh, 2, fila, TextCellValue(toma?.presionTexto ?? ''), _celda);
      _set(
          sh,
          3,
          fila,
          TextCellValue(toma == null
              ? ''
              : [
                  fDiaCorto.format(toma.fechaHora),
                  fHora.format(toma.fechaHora),
                  toma.medTexto,
                ].whereType<String>().join(' ')),
          _celda);
      _set(sh, 4, fila, TextCellValue(toma?.comentario ?? ''), _celda);
      fila++;
    }
    _merge(sh, 0, inicio, 0, fila - 1,
        TextCellValue('Día $dia (${fDiaCorto.format(serie.fechaDelDia(dia))})'), _celdaDia);
  }

  fila++;
  final resumenes = <(String, Resumen)>[
    ('Promedio (sin día 1)', r.principal),
    ('Promedio todas las tomas', r.todas),
    ('Mañana (sin día 1)', r.manana),
    ('Tarde (sin día 1)', r.tarde),
  ];
  for (final (etiqueta, res) in resumenes) {
    _merge(sh, 0, fila, 1, fila, TextCellValue(etiqueta), _etiqueta);
    _set(sh, 2, fila, TextCellValue(res.textoCompleto), _celda);
    _set(sh, 3, fila, TextCellValue('${res.n} tomas'), _celda);
    fila++;
  }

  sh.setColumnWidth(0, 18);
  sh.setColumnWidth(1, 12);
  sh.setColumnWidth(2, 20);
  sh.setColumnWidth(3, 24);
  sh.setColumnWidth(4, 40);

  _hojaDetalle(excel['Detalle'], r.tomas, serie: serie);

  await _compartir(excel, 'Presion_${_nombreArchivo(serie.nombre)}.xlsx',
      'Automonitoreo de presión - ${serie.nombre}');
}

void _hojaDetalle(Sheet sh, List<Toma> tomas,
    {Serie? serie, Serie? Function(int?)? buscarSerie}) {
  sh.appendRow([
    TextCellValue('Fecha'),
    TextCellValue('Hora'),
    if (buscarSerie != null) TextCellValue('Control'),
    TextCellValue('Día del control'),
    TextCellValue('Turno'),
    TextCellValue('Sistólica'),
    TextCellValue('Diastólica'),
    TextCellValue('Pulso'),
    TextCellValue('Medicación'),
    TextCellValue('Comentario'),
  ]);
  for (final t in tomas) {
    final s = serie ?? buscarSerie?.call(t.serieId);
    sh.appendRow([
      TextCellValue(fDia.format(t.fechaHora)),
      TextCellValue(fHora.format(t.fechaHora)),
      if (buscarSerie != null) TextCellValue(s?.nombre ?? ''),
      s == null ? null : IntCellValue(s.diaDe(t.fechaHora)),
      TextCellValue(t.turno.etiqueta),
      IntCellValue(t.sistolica),
      IntCellValue(t.diastolica),
      t.pulso == null ? null : IntCellValue(t.pulso!),
      TextCellValue(t.medTexto ?? ''),
      TextCellValue(t.comentario ?? ''),
    ]);
  }
  final columnas = buscarSerie != null ? 10 : 9;
  for (var c = 0; c < columnas; c++) {
    sh.cell(_ix(c, 0)).cellStyle = _encabezado;
    sh.setColumnWidth(c, c == columnas - 1 ? 40 : 14);
  }
}

/// Historial completo: todas las tomas y una hoja comparando los controles.
Future<void> exportarHistorial(
    List<Serie> series, List<Toma> tomas, Serie? Function(int?) buscarSerie) async {
  final excel = _nuevoLibro('Controles');
  final sh = excel['Controles'];

  sh.appendRow([
    TextCellValue('Control'),
    TextCellValue('Inicio'),
    TextCellValue('Fin'),
    TextCellValue('Tomas'),
    TextCellValue('Sistólica (sin día 1)'),
    TextCellValue('Diastólica (sin día 1)'),
    TextCellValue('Pulso (sin día 1)'),
    TextCellValue('Sist. mañana'),
    TextCellValue('Diast. mañana'),
    TextCellValue('Sist. tarde'),
    TextCellValue('Diast. tarde'),
  ]);
  for (final s in series.reversed) {
    final r = ResumenSerie(s, tomas.where((t) => t.serieId == s.id).toList());
    sh.appendRow([
      TextCellValue(s.nombre),
      TextCellValue(fDia.format(s.inicio)),
      TextCellValue(fDia.format(s.fin)),
      IntCellValue(r.tomas.length),
      _dec(r.principal.sis),
      _dec(r.principal.dia),
      _dec(r.principal.pulso),
      _dec(r.manana.sis),
      _dec(r.manana.dia),
      _dec(r.tarde.sis),
      _dec(r.tarde.dia),
    ]);
  }
  for (var c = 0; c < 11; c++) {
    sh.cell(_ix(c, 0)).cellStyle = _encabezado;
    sh.setColumnWidth(c, c == 0 ? 24 : 16);
  }

  final ordenadas = [...tomas]..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
  _hojaDetalle(excel['Tomas'], ordenadas, buscarSerie: buscarSerie);

  final hoy = DateFormat('yyyyMMdd').format(DateTime.now());
  await _compartir(excel, 'Presion_historial_$hoy.xlsx', 'Historial de presión');
}

/// Comparte una copia del archivo de la base (para no perder datos).
Future<void> compartirBackup() async {
  final dir = await getTemporaryDirectory();
  final nombre =
      'presion_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.db';
  final f = await Db.instance.copiaDeSeguridad(p.join(dir.path, nombre));
  await Share.shareXFiles([XFile(f.path)], subject: 'Backup app presión');
}
