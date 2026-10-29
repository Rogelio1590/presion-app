import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const colorSis = Color(0xFFD9534F);
const colorDia = Color(0xFF3F51B5);

/// Gráfico de líneas sistólica/diastólica con referencia 135/85.
class GraficoPresion extends StatelessWidget {
  const GraficoPresion({
    super.key,
    required this.etiquetas,
    required this.sis,
    required this.dia,
    this.altura = 220,
  });

  final List<String> etiquetas;
  final List<double?> sis;
  final List<double?> dia;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final valores = [...sis, ...dia].whereType<double>().toList();
    if (valores.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Sin datos todavía')),
      );
    }
    final minV = min(valores.reduce(min), 85.0);
    final maxV = max(valores.reduce(max), 135.0);
    final minY = ((minV - 10) / 10).floorToDouble() * 10;
    final maxY = ((maxV + 10) / 10).ceilToDouble() * 10;
    final n = etiquetas.length;

    LineChartBarData linea(List<double?> v, Color c) => LineChartBarData(
          spots: [
            for (var i = 0; i < v.length; i++)
              v[i] == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), v[i]!),
          ],
          color: c,
          barWidth: 3,
          isCurved: false,
          dotData: const FlDotData(show: true),
        );

    HorizontalLine ref(double y, Color c) => HorizontalLine(
          y: y,
          color: c.withValues(alpha: 0.45),
          strokeWidth: 1,
          dashArray: [6, 4],
        );

    const chico = TextStyle(fontSize: 11);

    return Column(
      children: [
        SizedBox(
          height: altura,
          child: Padding(
            padding: const EdgeInsets.only(right: 12, top: 8),
            child: LineChart(
              LineChartData(
                minX: n == 1 ? -1 : 0,
                maxX: n == 1 ? 1 : (n - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [linea(sis, colorSis), linea(dia, colorDia)],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [ref(135, colorSis), ref(85, colorDia)],
                ),
                gridData: const FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 20,
                      getTitlesWidget: (v, meta) =>
                          Text(v.toInt().toString(), style: chico),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (v, meta) {
                        final i = v.round();
                        if ((v - i).abs() > 0.01 || i < 0 || i >= n) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(etiquetas[i], style: chico),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 16,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _Leyenda(color: colorSis, texto: 'Sistólica'),
            _Leyenda(color: colorDia, texto: 'Diastólica'),
            _Leyenda(color: Colors.grey, texto: 'Ref. 135/85', punteada: true),
          ],
        ),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto, this.punteada = false});

  final Color color;
  final String texto;
  final bool punteada;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: punteada ? 2 : 4,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
