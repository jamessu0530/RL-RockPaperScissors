import 'dart:math';
import '../models/janken_model.dart';

/// Random（隨機基準線）
///
/// 不學習，永遠隨機出拳。
/// 做為基準線：其他模型的勝率如果沒比 Random 好，代表沒學到東西。
class JankenRandom extends JankenModel {
  @override
  String get modelName => 'Random';

  final Random _rng = Random();

  int _total = 0;
  int _userWins = 0;
  int _cpuWins = 0;
  int _draws = 0;
  String _prevContext = 'N';
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

  @override
  String selectAction() => JankenModel.choices[_rng.nextInt(3)];

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
    if (_prevContext != 'N') {
      _whenUserPrevTotal[_prevContext] = _whenUserPrevTotal[_prevContext]! + 1;
      if (userWon) _whenUserPrevUserWins[_prevContext] = _whenUserPrevUserWins[_prevContext]! + 1;
      if (r == '你輸了') _whenUserPrevCpuWins[_prevContext] = _whenUserPrevCpuWins[_prevContext]! + 1;
    }

    _prevContext = userChoice;
    lastUserChoice = userChoice;
    lastCpuChoice = cpu;
    lastResult = r;

    final decided = _userWins + _cpuWins;
    winRateHistory.add(decided > 0 ? _userWins / decided * 100 : 0);
  }
}
