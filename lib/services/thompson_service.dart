import 'dart:math';
import '../models/janken_model.dart';

/// Thompson Sampling（貝氏 Bandit）
///
/// 跟 Contextual Bandit 同屬 Bandit 系列，但探索策略不同：
/// - 不用 ε-greedy，而是用 Beta 分佈取樣
/// - 每個 (state, action) 維護 alpha（成功）和 beta（失敗）
/// - 選動作時，從每個 action 的 Beta(alpha, beta) 取樣，選最大的
/// - 天生有「不確定的多探索、確定的多利用」的性質
class JankenThompson extends JankenModel {
  @override
  String get modelName => 'Thompson Sampling';

  String _context = 'N';
  final Random _rng = Random();

  // Beta 分佈參數：_alpha[state][action] 和 _beta[state][action]
  final Map<String, Map<String, double>> _alpha = {};
  final Map<String, Map<String, double>> _beta = {};

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

  double _getAlpha(String state, String action) {
    _alpha[state] ??= {};
    return _alpha[state]![action] ??= 1.0; // 先驗 Beta(1,1) = uniform
  }

  double _getBeta(String state, String action) {
    _beta[state] ??= {};
    return _beta[state]![action] ??= 1.0;
  }

  /// 從 Beta(alpha, beta) 取樣（用 Gamma 分佈近似）
  double _sampleBeta(double a, double b) {
    final x = _sampleGamma(a);
    final y = _sampleGamma(b);
    return x / (x + y);
  }

  /// Gamma(shape, 1) 取樣：Marsaglia and Tsang's method
  double _sampleGamma(double shape) {
    if (shape < 1.0) {
      return _sampleGamma(shape + 1.0) * pow(_rng.nextDouble(), 1.0 / shape);
    }
    final d = shape - 1.0 / 3.0;
    final c = 1.0 / sqrt(9.0 * d);
    while (true) {
      double x, v;
      do {
        x = _randomNormal();
        v = 1.0 + c * x;
      } while (v <= 0);
      v = v * v * v;
      final u = _rng.nextDouble();
      if (u < 1.0 - 0.0331 * (x * x) * (x * x)) return d * v;
      if (log(u) < 0.5 * x * x + d * (1.0 - v + log(v))) return d * v;
    }
  }

  double _randomNormal() {
    final u1 = _rng.nextDouble();
    final u2 = _rng.nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }

  @override
  String selectAction() {
    double bestSample = double.negativeInfinity;
    final bestActions = <String>[];
    for (final a in JankenModel.choices) {
      final sample = _sampleBeta(_getAlpha(_context, a), _getBeta(_context, a));
      if (sample > bestSample) {
        bestSample = sample;
        bestActions
          ..clear()
          ..add(a);
      } else if (sample == bestSample) {
        bestActions.add(a);
      }
    }
    return bestActions[_rng.nextInt(bestActions.length)];
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
    if (_context != 'N') {
      _whenUserPrevTotal[_context] = _whenUserPrevTotal[_context]! + 1;
      if (userWon) _whenUserPrevUserWins[_context] = _whenUserPrevUserWins[_context]! + 1;
      if (r == '你輸了') _whenUserPrevCpuWins[_context] = _whenUserPrevCpuWins[_context]! + 1;
    }

    // 更新 Beta 分佈：贏了 +alpha，輸了 +beta
    _alpha[_context] ??= {};
    _beta[_context] ??= {};
    if (r == '你輸了') {
      _alpha[_context]![cpu] = _getAlpha(_context, cpu) + 1.0;
    } else if (r == '你贏了') {
      _beta[_context]![cpu] = _getBeta(_context, cpu) + 1.0;
    }

    _context = userChoice;
    lastUserChoice = userChoice;
    lastCpuChoice = cpu;
    lastResult = r;

    final decided = _userWins + _cpuWins;
    winRateHistory.add(decided > 0 ? _userWins / decided * 100 : 0);
  }
}
