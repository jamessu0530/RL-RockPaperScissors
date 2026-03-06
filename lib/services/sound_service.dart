import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final _player = AudioPlayer();

  Future<void> playTap() => _play('sounds/tap.wav');
  Future<void> playWin() => _play('sounds/win.wav');
  Future<void> playLose() => _play('sounds/lose.wav');
  Future<void> playDraw() => _play('sounds/draw.wav');

  Future<void> playResult(String result) {
    switch (result) {
      case '你贏了':
        return playWin();
      case '你輸了':
        return playLose();
      default:
        return playDraw();
    }
  }

  Future<void> _play(String assetPath) async {
    await _player.stop();
    await _player.play(AssetSource(assetPath));
  }
}
