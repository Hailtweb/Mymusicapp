// lib/services/audio_manager.dart
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioManager {
  // 1. Áp dụng Singleton Pattern (Đảm bảo chỉ có 1 instance tồn tại)
  AudioManager._internal();
  static final AudioManager instance = AudioManager._internal();

  // 2. Tạo đối tượng AudioPlayer của just_audio
  final AudioPlayer player = AudioPlayer();

  // 3. Hàm nạp danh sách bài hát (Playlist) vào máy phát
  Future<void> initPlaylist(List<Song> songs) async {
    try {
      // Biến đổi List<Song> của chúng ta thành AudioSource của just_audio
      final playlist = ConcatenatingAudioSource(
        children: songs.map((song) => AudioSource.uri(
          Uri.parse(song.url),
          tag: song, // Gắn kèm thông tin bài hát vào đây để lúc sau lôi ra dùng
        )).toList(),
      );

      // Nạp băng đĩa vào máy
      await player.setAudioSource(playlist);
    } catch (e) {
      print("Lỗi khi nạp Playlist: $e");
    }
  }

  // 4. Giải phóng bộ nhớ khi tắt app (Rất quan trọng để tránh rò rỉ RAM)
  void dispose() {
    player.dispose();
  }
}