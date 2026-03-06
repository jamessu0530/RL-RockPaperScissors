/// 所有猜拳 AI 模型的共用介面
abstract class JankenModel {
  static const List<String> choices = ['剪刀', '石頭', '布'];

  String get modelName;

  String? lastUserChoice;
  String? lastCpuChoice;
  String lastResult = '選一個出拳';

  /// 每局結束後的累計勝率（不含平手），用來畫曲線圖
  final List<double> winRateHistory = [];

  int get total;
  int get userWins;
  int get cpuWins;
  int get draws;
  Map<String, int> get whenCpuPlayedTotal;
  Map<String, int> get whenCpuPlayedUserWins;
  Map<String, int> get whenCpuPlayedCpuWins;
  Map<String, int> get whenUserPrevTotal;
  Map<String, int> get whenUserPrevUserWins;
  Map<String, int> get whenUserPrevCpuWins;

  /// 電腦選出拳
  String selectAction();

  /// 玩家出 userChoice，內部更新模型與統計
  void play(String userChoice);

  static String rateStringExclDraws(int wins, int losses) {
    final total = wins + losses;
    if (total == 0) return '-';
    return '${(wins / total * 100).toStringAsFixed(1)}%';
  }
}
