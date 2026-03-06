import 'package:flutter/material.dart';
import '../models/janken_model.dart';
import '../styles/app_styles.dart';
import 'chart_page.dart';

/// 第二頁：顯示每位玩家在每個模型下的勝率統計
class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.players});

  final Map<String, Map<String, JankenModel>> players;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('勝率統計'),
        backgroundColor: colorScheme.inversePrimary,
        foregroundColor: colorScheme.onInverseSurface,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChartPage(players: players)),
            ),
            icon: const Icon(Icons.show_chart),
            tooltip: '勝率曲線',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppStyles.bodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final playerEntry in players.entries) ...[
              Text(playerEntry.key, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              )),
              const SizedBox(height: AppStyles.spacingSm),
              for (final modelEntry in playerEntry.value.entries) ...[
                _ModelStatsSection(name: modelEntry.key, model: modelEntry.value),
                const SizedBox(height: AppStyles.spacingMd),
              ],
              const Divider(),
              const SizedBox(height: AppStyles.spacingMd),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModelStatsSection extends StatelessWidget {
  const _ModelStatsSection({required this.name, required this.model});

  final String name;
  final JankenModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(name, style: AppStyles.sectionTitle(context)),
        const SizedBox(height: AppStyles.spacingSm),
        Card(
          child: Padding(
            padding: AppStyles.cardPaddingSmall,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('總局數：${model.total}'),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: '勝率：'),
                      TextSpan(
                        text: JankenModel.rateStringExclDraws(model.userWins, model.cpuWins),
                        style: TextStyle(
                          color: AppStyles.rateColor(model.userWins, model.cpuWins, context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '（${model.userWins} 勝 / ${model.cpuWins} 負 / ${model.draws} 平）',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppStyles.spacingSm),
        Text('依電腦出的手', style: AppStyles.subsectionTitle(context)),
        _StatRow('電腦出剪刀時', model.whenCpuPlayedUserWins['剪刀']!, model.whenCpuPlayedCpuWins['剪刀']!),
        _StatRow('電腦出石頭時', model.whenCpuPlayedUserWins['石頭']!, model.whenCpuPlayedCpuWins['石頭']!),
        _StatRow('電腦出布時', model.whenCpuPlayedUserWins['布']!, model.whenCpuPlayedCpuWins['布']!),
        const SizedBox(height: AppStyles.spacingSm),
        Text('依上局出的手', style: AppStyles.subsectionTitle(context)),
        _StatRow('上局出剪刀時', model.whenUserPrevUserWins['剪刀']!, model.whenUserPrevCpuWins['剪刀']!),
        _StatRow('上局出石頭時', model.whenUserPrevUserWins['石頭']!, model.whenUserPrevCpuWins['石頭']!),
        _StatRow('上局出布時', model.whenUserPrevUserWins['布']!, model.whenUserPrevCpuWins['布']!),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.wins, this.losses);

  final String label;
  final int wins;
  final int losses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppStyles.statRowPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            JankenModel.rateStringExclDraws(wins, losses),
            style: AppStyles.bodyMediumBold(context).copyWith(
              color: AppStyles.rateColor(wins, losses, context),
            ),
          ),
        ],
      ),
    );
  }
}
