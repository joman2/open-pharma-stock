import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  SoundPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  Future<void> playScanAccepted() async {
    await _player.play(AssetSource('sounds/scan_beep.wav'));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
