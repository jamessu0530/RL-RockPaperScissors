import 'dart:math';
import '../models/janken_model.dart';

/// UCB1（Upper Confidence Bound）
///
/// 跟 ε-greedy 和 Thompson Sampling 同屬 Bandit 系列，但探索策略不同：
/// - 選動作時用 UCB 公式：Q(s,a) + c * sqrt(ln(N) / n(s,a))
/// - Q(s,a) = 平均 reward（利用項）
/// - c * sqrt(ln(N) / n(s,a)) = 信賴上界（探索項：被選越少次、探索越多）
/// - 不需要 ε 或機率取樣，純粹靠公式平衡 exploration vs exploitation
class JankenUCB extends JankenModel {
  @override
  String get modelName => 'UCB1';

  String _context = 'N';
  static const double _c = 1.4; // 探索係數
  final Random _rng = Random();

  // Q table：sum 和 count
  final Map<String, Map<String, _UCBEntry>> _q = {};

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

  _UCBEntry _getEntry(String state, String action) {
    _q[state] ??= {};
    _q[state]![action] ??= _UCBEntry();
    return _q[state]![action]!;
  }

  /// 在該 state 下各 action 被選的總次數
  int _totalVisits(String state) {
    int sum = 0;
    for (final a in JankenModel.choices) {
      sum += _getEntry(state, a).count;
    }
    return sum;
  }

  @override
  String selectAction() {
    final n = _totalVisits(_context);

    // 還有沒試過的 action，先試
    final untried = <String>[];
    for (final a in JankenModel.choices) {
      if (_getEntry(_context, a).count == 0) untried.add(a);
    }
    if (untried.isNotEmpty) {
      return untried[_rng.nextInt(untried.length)];
    }

    double bestUCB = double.negativeInfinity;
    final bestActions = <String>[];
    for (final a in JankenModel.choices) {
      final entry = _getEntry(_context, a);
      final ucb = entry.mean + _c * sqrt(log(n) / entry.count);
      if (ucb > bestUCB) {
        bestUCB = ucb;
        bestActions
          ..clear()
          ..add(a);
      } else if (ucb == bestUCB) {
        bestActions.add(a);
      }
    }
    return bestActions[_rng.nextInt(bestActions.length)];
  }

  static int _reward(String resultText) {
    if (resultText == '你輸了') return 1;
    if (resultText == '你贏了') return -1;
    return 0;
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

    final rew = _reward(r);
    final userWon = r == '你贏了';

    _total++;
    if (userWon) _userWins++;
    if (r == '你輸了') _cpuWins++;
    if (r == '平手') _draws++;

    _whenCpuPlayedTotal[cpu] = _whenCpuPlayedTotal[cpu]! + 1;
    if (userWon) _whenCpuPlayedUserWins[cpu] = _whenCpuPlayedUserWins[cpu]! + 1;
    if (r == '你輸了') _whenCpuPlayedCpuWins[cpu] = _whenCpuPlayedCpuWins[cpu]! + 1;
    if (_context != 'N') {
      _whenUserPrevTotal[_context] = _whenUserPrevTotal[_context]! + 1;
      if (userWon) _whenUserPrevUserWins[_context] = _whenUserPrevUserWins[_context]! + 1;
      if (r == '你輸了') _whenUserPrevCpuWins[_context] = _whenUserPrevCpuWins[_context]! + 1;
    }

    final entry = _getEntry(_context, cpu);
    entry.sum += rew;
    entry.count++;

    _context = userChoice;
    lastUserChoice = userChoice;
    lastCpuChoice = cpu;
    lastResult = r;

    final decided = _userWins + _cpuWins;
    winRateHistory.add(decided > 0 ? _userWins / decided * 100 : 0);
  }
}

class _UCBEntry {
  int sum = 0;
  int count = 0;
  double get mean => count == 0 ? 0.0 : sum / count;
}
