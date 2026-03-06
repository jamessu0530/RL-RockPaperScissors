import 'dart:math';
import '../models/janken_model.dart';

/// 馬可夫鏈：用轉移機率矩陣預測玩家下一步，出能剋制的那一手
///
/// - 狀態 = 玩家上一局出什麼
/// - 記錄 transition[prev][next] 的次數
/// - 預測：在目前 state 下，找 argmax_next transition[state][next]
/// - 電腦出能贏 predicted 的手
class JankenMarkov extends JankenModel {
  @override
  String get modelName => '馬可夫鏈';

  static const String _stateNone = 'N';
  String _state = _stateNone;
  final Random _rng = Random();

  // transition[prev][next] = count
  final Map<String, Map<String, int>> _transition = {};

  int _total = 0;
  int _userWins = 0;
  int _cpuWins = 0;
  int _draws = 0;
  final Map<String, int> _whenCpuPlayedTotal = {'剪刀': 0, '石頭': 0, '布': 0};
  final Map<String, int> _whenCpuPlayedUserWins = {'剪刀': 0, '石頭': 0, '布': 0};
  final Map<String, int> _whenCpuPlayedCpuWins = {'剪刀': 0, '石頭': 0, '布': 0};
  final Map<String, int> _whenUserPrevTotal = {'剪刀': 0, '石頭': 0, '布': 0};
  final Map<String, int> _whenUserPrevUserWins = {'剪刀': 0, '石頭': 0, '布': 0};
  final Map<String, int> _whenUserPrevCpuWins = {'剪刀': 0, '石頭': 0, '布': 0};

  @override int get total => _total;
  @override int get userWins => _userWins;
  @override int get cpuWins => _cpuWins;
  @override int get draws => _draws;
  @override Map<String, int> get whenCpuPlayedTotal => Map.unmodifiable(_whenCpuPlayedTotal);
  @override Map<String, int> get whenCpuPlayedUserWins => Map.unmodifiable(_whenCpuPlayedUserWins);
  @override Map<String, int> get whenCpuPlayedCpuWins => Map.unmodifiable(_whenCpuPlayedCpuWins);
  @override Map<String, int> get whenUserPrevTotal => Map.unmodifiable(_whenUserPrevTotal);
  @override Map<String, int> get whenUserPrevUserWins => Map.unmodifiable(_whenUserPrevUserWins);
  @override Map<String, int> get whenUserPrevCpuWins => Map.unmodifiable(_whenUserPrevCpuWins);

  int _getCount(String prev, String next) {
    return _transition[prev]?[next] ?? 0;
  }

  void _addCount(String prev, String next) {
    _transition[prev] ??= {};
    _transition[prev]![next] = (_transition[prev]![next] ?? 0) + 1;
  }

  /// 出能剋制 predicted 的那一手
  static String _counter(String predicted) {
    switch (predicted) {
      case '剪刀': return '石頭';
      case '石頭': return '布';
      case '布': return '剪刀';
      default: return JankenModel.choices[Random().nextInt(3)];
    }
  }

  /// 預測玩家下一步：argmax_next P(next|state)；同分隨機
  String _predict() {
    int bestCount = -1;
    final bestMoves = <String>[];
    for (final next in JankenModel.choices) {
      final c = _getCount(_state, next);
      if (c > bestCount) {
        bestCount = c;
        bestMoves
          ..clear()
          ..add(next);
      } else if (c == bestCount) {
        bestMoves.add(next);
      }
    }
    return bestMoves[_rng.nextInt(bestMoves.length)];
  }

  @override
  String selectAction() {
    // 如果目前 state 完全沒資料，隨機出
    final hasData = _transition[_state]?.values.any((v) => v > 0) ?? false;
    if (!hasData) return JankenModel.choices[_rng.nextInt(3)];
    return _counter(_predict());
  }

  @override
  void play(String userChoice) {
    final cpu = selectAction();

    String r;
    if (userChoice == cpu) {
      r = '平手';
    } else if ((userChoice == '剪刀' && cpu == '布') ||
        (userChoice == '石頭' && cpu == '剪刀') ||
        (userChoice == '布' && cpu == '石頭')) {
      r = '你贏了';
    } else {
      r = '你輸了';
    }

    final userWon = r == '你贏了';

    _total++;
    if (userWon) _userWins++;
    if (r == '你輸了') _cpuWins++;
    if (r == '平手') _draws++;

    _whenCpuPlayedTotal[cpu] = _whenCpuPlayedTotal[cpu]! + 1;
    if (userWon) _whenCpuPlayedUserWins[cpu] = _whenCpuPlayedUserWins[cpu]! + 1;
    if (r == '你輸了') _whenCpuPlayedCpuWins[cpu] = _whenCpuPlayedCpuWins[cpu]! + 1;
    if (_state != _stateNone) {
      _whenUserPrevTotal[_state] = _whenUserPrevTotal[_state]! + 1;
      if (userWon) _whenUserPrevUserWins[_state] = _whenUserPrevUserWins[_state]! + 1;
      if (r == '你輸了') _whenUserPrevCpuWins[_state] = _whenUserPrevCpuWins[_state]! + 1;
    }

    // 更新轉移矩陣：state → userChoice
    _addCount(_state, userChoice);

    _state = userChoice;
    lastUserChoice = userChoice;
    lastCpuChoice = cpu;
    lastResult = r;

    final decided = _userWins + _cpuWins;
    winRateHistory.add(decided > 0 ? _userWins / decided * 100 : 0);
  }
}
