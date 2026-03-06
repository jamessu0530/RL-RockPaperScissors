import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/janken_model.dart';
import '../styles/app_styles.dart';

/// 曲線圖頁面：每位玩家一張圖，5 條線代表 5 個模型的勝率變化
/// 觸碰拖移時在圖下方顯示各模型數據，預設顯示最新數據
class ChartPage extends StatefulWidget {
  const ChartPage({super.key, required this.players});

  final Map<String, Map<String, JankenModel>> players;

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  static const _lineColors = [
    Colors.white,
    Colors.blue,
    Colors.amber,
    Colors.teal,
    Colors.grey,
  ];

  // 每位玩家各自追蹤觸碰到的局數（null = 顯示最新）
  final Map<String, int?> _touchedIndex = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('勝率曲線'),
        backgroundColor: colorScheme.inversePrimary,
        foregroundColor: colorScheme.onInverseSurface,
      ),
      body: SingleChildScrollView(
        padding: AppStyles.bodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final playerEntry in widget.players.entries) ...[
              Text(playerEntry.key, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              )),
              const SizedBox(height: AppStyles.spacingSm),
              _buildChart(context, playerEntry.key, playerEntry.value),
              const SizedBox(height: AppStyles.spacingSm),
              _buildLegend(context, playerEntry.value),
              const SizedBox(height: AppStyles.spacingSm),
              _buildDataPanel(context, playerEntry.key, playerEntry.value),
              const Divider(),
              const SizedBox(height: AppStyles.spacingLg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, String playerKey, Map<String, JankenModel> models) {
    final entries = models.entries.toList();
    final hasData = entries.any((e) => e.value.winRateHistory.isNotEmpty);

    if (!hasData) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('尚無資料，出拳後會顯示曲線')),
      );
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent,
              getTooltipItems: (_) => [for (final _ in entries) null],
            ),
            touchCallback: (event, response) {
              final spots = response?.lineBarSpots;
              if (spots != null && spots.isNotEmpty) {
                final idx = spots.first.x.toInt();
                setState(() => _touchedIndex[playerKey] = idx);
                return;
              }
              if (event is FlLongPressEnd || event is FlPanEndEvent || event is FlTapUpEvent) {
                setState(() => _touchedIndex[playerKey] = null);
              }
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  if (value == value.roundToDouble()) {
                    return Text('${value.toInt()}', style: Theme.of(context).textTheme.bodySmall);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade800, strokeWidth: 0.5),
            getDrawingVerticalLine: (_) => FlLine(color: Colors.grey.shade800, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade700)),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(y: 50, color: Colors.grey.shade600, strokeWidth: 1, dashArray: [5, 5]),
            ],
          ),
          lineBarsData: [
            for (var i = 0; i < entries.length; i++)
              _buildLine(entries[i].value.winRateHistory, _lineColors[i % _lineColors.length]),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<double> history, Color color) {
    return LineChartBarData(
      spots: [for (var i = 0; i < history.length; i++) FlSpot(i.toDouble(), history[i])],
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }

  Widget _buildLegend(BuildContext context, Map<String, JankenModel> models) {
    final entries = models.entries.toList();
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (var i = 0; i < entries.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 12, color: _lineColors[i % _lineColors.length]),
              const SizedBox(width: 4),
              Text(entries[i].key, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }

  /// 圖下方的數據面板：拖移時顯示該局數據，沒拖移顯示最新數據
  Widget _buildDataPanel(BuildContext context, String playerKey, Map<String, JankenModel> models) {
    final entries = models.entries.toList();
    final hasData = entries.any((e) => e.value.winRateHistory.isNotEmpty);
    if (!hasData) return const SizedBox.shrink();

    final idx = _touchedIndex[playerKey];
    final maxLen = entries.map((e) => e.value.winRateHistory.length).reduce((a, b) => a > b ? a : b);
    final displayIdx = idx ?? (maxLen - 1);

    return Card(
      child: Padding(
        padding: AppStyles.cardPaddingSmall,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              idx == null ? '最新數據（第 $maxLen 局）' : '第 ${displayIdx + 1} 局',
              style: AppStyles.subsectionTitle(context),
            ),
            const SizedBox(height: AppStyles.spacingXs),
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, color: _lineColors[i % _lineColors.length]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entries[i].key, style: Theme.of(context).textTheme.bodySmall)),
                    Text(
                      displayIdx < entries[i].value.winRateHistory.length
                          ? '${entries[i].value.winRateHistory[displayIdx].toStringAsFixed(1)}%'
                          : '-',
                      style: AppStyles.bodyMediumBold(context).copyWith(
                        color: displayIdx < entries[i].value.winRateHistory.length
                            ? AppStyles.rateColor(
                                (entries[i].value.winRateHistory[displayIdx] > 50) ? 1 : 0,
                                (entries[i].value.winRateHistory[displayIdx] < 50) ? 1 : 0,
                                context,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
