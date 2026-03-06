import 'package:flutter/material.dart';
import '../models/janken_model.dart';
import '../services/bandit_service.dart';
import '../services/markov_service.dart';
import '../services/thompson_service.dart';
import '../services/ucb_service.dart';
import '../services/random_service.dart';
import '../widgets/janken_buttons.dart';
import '../styles/app_styles.dart';
import '../services/sound_service.dart';
import 'stats_page.dart';
import 'chart_page.dart';

Map<String, JankenModel> _createModels() => {
  'Contextual Bandit': JankenBandit(),
  '馬可夫鏈': JankenMarkov(),
  'Thompson Sampling': JankenThompson(),
  'UCB1': JankenUCB(),
  'Random（基準線）': JankenRandom(),
};

class JankenPage extends StatefulWidget {
  const JankenPage({super.key});

  @override
  State<JankenPage> createState() => _JankenPageState();
}

class _JankenPageState extends State<JankenPage> {
  // 每位玩家有自己的一組 5 個模型
  final Map<String, Map<String, JankenModel>> _players = {
    '玩家 1': _createModels(),
  };
  late String _currentPlayer = _players.keys.first;
  Map<String, JankenModel> get _models => _players[_currentPlayer]!;

  String? _lastChoice;

  final _sound = SoundService.instance;

  void _play(String choice) {
    setState(() {
      _lastChoice = choice;
      for (final model in _models.values) {
        model.play(choice);
      }
    });
    final firstResult = _models.values.first.lastResult;
    _sound.playResult(firstResult);
  }

  void _addPlayer() {
    final nextId = _players.length + 1;
    final name = '玩家 $nextId';
    setState(() {
      _players[name] = _createModels();
      _currentPlayer = name;
    });
  }

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatsPage(players: _players)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('猜拳'),
        backgroundColor: colorScheme.inversePrimary,
        foregroundColor: colorScheme.onInverseSurface,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChartPage(players: _players)),
            ),
            icon: const Icon(Icons.show_chart),
            tooltip: '勝率曲線',
          ),
          IconButton(
            onPressed: _openStats,
            icon: const Icon(Icons.bar_chart),
            tooltip: '勝率統計',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppStyles.bodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 玩家選擇
            Text('玩家', style: AppStyles.sectionTitle(context)),
            const SizedBox(height: AppStyles.spacingSm),
            Card(
              child: Padding(
                padding: AppStyles.cardPaddingSmall,
                child: Column(
                  children: [
                    for (final name in _players.keys)
                      RadioListTile<String>(
                        title: Text(name),
                        subtitle: Text('已玩 ${_players[name]!.values.first.total} 局'),
                        value: name,
                        groupValue: _currentPlayer,
                        onChanged: (v) => setState(() => _currentPlayer = v!),
                        activeColor: colorScheme.primary,
                      ),
                    TextButton.icon(
                      onPressed: _addPlayer,
                      icon: const Icon(Icons.person_add),
                      label: const Text('新增玩家'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppStyles.spacingMd),

            // 出拳
            Text('出拳', style: AppStyles.subsectionTitle(context)),
            const SizedBox(height: AppStyles.spacingSm),
            JankenButtons(onChoice: _play),
            const SizedBox(height: AppStyles.spacingLg),

            // 本局各模型結果
            Text('本局結果', style: AppStyles.sectionTitle(context)),
            const SizedBox(height: AppStyles.spacingSm),
            if (_lastChoice == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('出拳後顯示各模型對戰結果')),
                ),
              )
            else
              for (final entry in _models.entries)
                Card(
                  child: Padding(
                    padding: AppStyles.cardPaddingSmall,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(entry.key, style: AppStyles.bodyMediumBold(context)),
                            ),
                            Text(
                              entry.value.lastResult,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppStyles.resultColor(entry.value.lastResult, context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '你：$_lastChoice　電腦：${entry.value.lastCpuChoice}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

            const SizedBox(height: AppStyles.spacingMd),
            OutlinedButton.icon(
              onPressed: _openStats,
              icon: const Icon(Icons.bar_chart),
              label: const Text('查看各玩家 / 模型勝率'),
            ),
            const SizedBox(height: AppStyles.spacingSm),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChartPage(players: _players)),
              ),
              icon: const Icon(Icons.show_chart),
              label: const Text('查看勝率曲線'),
            ),
          ],
        ),
      ),
    );
  }
}
