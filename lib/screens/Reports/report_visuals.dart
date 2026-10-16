import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

/// Chart colors validated (contrast/band checks) against the surfaces the
/// charts render on — `AppTheme.surfaceColor`, i.e. white in light mode and
/// [AppTheme.darkSurface] in dark. `mediumPurple` fails the light-mode
/// eligibility band, so the two modes use tuned series sets.
class ChartPalette {
  final List<Color> series;
  const ChartPalette(this.series);

  /// slot 1 = data bars/line, slot 2 = an optional second series.
  static ChartPalette of(bool isDark) => isDark
      ? const ChartPalette([Color(0xFFAB8726), Color(0xFF8E6BBF)])
      : const ChartPalette([AppTheme.primaryGold, AppTheme.lightPurple]);

  /// One-hue gold ramp for donut slices, bright → deep (slice 0 = biggest
  /// value). The legend below the donut pairs each label with its color, so
  /// nothing relies on hue recognition alone.
  static List<Color> ordinalGold(bool isDark) => isDark
      ? const [
          Color(0xFFF0DBA0),
          AppTheme.primaryGold,
          Color(0xFFB58B24),
          Color(0xFF8F6C14),
        ]
      : const [
          AppTheme.primaryGold,
          Color(0xFFB58B24),
          Color(0xFF8F6C14),
          Color(0xFF6B4F0E),
        ];

  static Color get otherSlice => AppTheme.hairline;
}

/// Label of the folded slice every slice past the fold limit rolls into.
const String otherSliceLabel = '(Other)';

Color donutSliceColor(int index, String label, bool isDark) {
  if (label == otherSliceLabel) return ChartPalette.otherSlice;
  final ramp = ChartPalette.ordinalGold(isDark);
  return ramp[index % ramp.length];
}

TextStyle _axisStyle(Color color) => TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 10,
      color: color,
    );

TextStyle get _tooltipStyle => TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textColor,
    );

String _truncate(String s) =>
    s.length <= 10 ? s : '${s.substring(0, 10)}…';

/// KPI tile: icon + label + big value (+ optional muted caption).
/// `valueColor` tints the value only (e.g. AppTheme.error for debt) — status
/// is never color-alone since the label carries the meaning.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final String? caption;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.goldBorderDecoration(radius: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AppTheme.primaryGold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Titled surface for a dashboard section (chart, table, …).
class DashboardCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const DashboardCard({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: AppTheme.goldBorderDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: DefaultTextStyle.merge(
              style: theme.textTheme.titleLarge,
              child: Row(
                children: [
                  Expanded(child: Text(title)),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Time series (line + area wash). Chart code is written against the
/// fl_chart 0.71 API: tooltip colors arrive through `getTooltipColor`
/// (renamed from `tooltipBgColor` in older 0.6x, and from 1.x onwards).
Widget buildTimeSeriesChart({
  required List<String> xLabels,
  required List<double> values,
  required ChartPalette palette,
  required String Function(double value) axisFormatter,
  required String Function(double value) tooltipFormatter,
  required String Function(String label) shortLabel,
}) {
  final seriesColor = palette.series.first;
  final n = values.length < xLabels.length ? values.length : xLabels.length;
  final bottomInterval = n > 8 ? (n / 8).ceilToDouble() : 1.0;
  // With dots off a single-point series would be invisible — show dots on
  // short series, keep the line clean on long ones.
  final showDots = n <= 12;
  return LineChart(
    LineChartData(
      minX: 0,
      maxX: n > 1 ? (n - 1).toDouble() : 1,
      minY: 0,
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 56,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child:
                  Text(axisFormatter(value), style: _axisStyle(AppTheme.mutedText)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: n > 1,
            interval: bottomInterval,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= n || (value - i).abs() > 0.001) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(shortLabel(xLabels[i]),
                    style: _axisStyle(AppTheme.mutedText)),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppTheme.hairline, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < n; i++) FlSpot(i.toDouble(), values[i]),
          ],
          barWidth: 2,
          color: seriesColor,
          dotData: FlDotData(show: showDots),
          belowBarData:
              BarAreaData(show: true, color: seriesColor.withOpacity(0.10)),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppTheme.raisedColor,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) => [
            for (final spot in touchedSpots)
              LineTooltipItem(
                '${shortLabel(xLabels[spot.x.toInt().clamp(0, n - 1)])} · '
                '${tooltipFormatter(spot.y)}',
                _tooltipStyle,
              ),
          ],
        ),
      ),
    ),
  );
}

/// Horizontal-ranking bar chart (vertical rods, biggest value left).
Widget buildRankedBarChart({
  required List<String> labels,
  required List<double> values,
  required ChartPalette palette,
  required String Function(double value) axisFormatter,
  required String Function(double value) tooltipFormatter,
}) {
  final seriesColor = palette.series.first;
  final n = values.length < labels.length ? values.length : labels.length;
  final labelInterval = n > 8 ? (n / 8).ceilToDouble() : 1.0;
  final maxV =
      n == 0 ? 0.0 : values.take(n).reduce(math.max);
  final maxY = maxV <= 0 ? 1.0 : maxV * 1.15;
  return BarChart(
    BarChartData(
      minY: 0,
      maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppTheme.hairline, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            interval: maxY / 4,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child:
                  Text(axisFormatter(value), style: _axisStyle(AppTheme.mutedText)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: labelInterval,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= n || (value - i).abs() > 0.001) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(_truncate(labels[i]),
                    style: _axisStyle(AppTheme.mutedText)),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < n; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: seriesColor,
                width: 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
      ],
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppTheme.raisedColor,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
            '${labels[group.x]} · ${tooltipFormatter(values[group.x])}',
            _tooltipStyle,
          ),
        ),
      ),
    ),
  );
}

/// Donut share chart with a dot legend underneath. fl_chart 0.71 removed
/// touch tooltips from PieTouchData, so percentages are printed on the
/// slices (≥ 8%) and the legend carries every label — no hidden info.
/// Slices arrive pre-sorted desc with >6 folded into [otherSliceLabel].
Widget buildShareDonutChart({
  required List<(String, double)> slices,
  required bool isDark,
}) {
  final total = slices.fold(0.0, (acc, s) => acc + s.$2);
  String pctText(double pct) =>
      '${pct.toStringAsFixed(pct >= 10 ? 0 : 1)}%';
  return Column(
    children: [
      Expanded(
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 44,
            pieTouchData: PieTouchData(enabled: false),
            sections: [
              for (var i = 0; i < slices.length; i++)
                () {
                  final color = donutSliceColor(i, slices[i].$1, isDark);
                  final pct = total > 0 ? slices[i].$2 / total * 100 : 0.0;
                  return PieChartSectionData(
                    value: slices[i].$2,
                    color: color,
                    radius: 64,
                    title: pct >= 8 ? pctText(pct) : '',
                    titleStyle: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.computeLuminance() > 0.55
                          ? AppTheme.darkText
                          : Colors.white,
                    ),
                  );
                }(),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 16,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < slices.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: donutSliceColor(i, slices[i].$1, isDark),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_truncateLong(slices[i].$1, 22)}'
                      '${total > 0 ? ' ${(slices[i].$2 / total * 100).toStringAsFixed(1)}%' : ''}',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

String _truncateLong(String s, int max) =>
    s.length <= max ? s : '${s.substring(0, max)}…';