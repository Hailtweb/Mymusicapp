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
  // Thêm tham số initialIndex (mặc định là 0)
  Future<void> initPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    try {
      final playlist = ConcatenatingAudioSource(
        children: songs.map((song) => AudioSource.uri(
          Uri.parse(song.url),
          tag: song, 
        )).toList(),
      );
      
      // Nạp băng đĩa và CẮM THẲNG KIM ĐỌC VÀO BÀI ĐƯỢC CHỌN
      await player.setAudioSource(playlist, initialIndex: initialIndex);
    } catch (e) {
      print("Lỗi khi nạp Playlist: $e");
    }
  }

  // 4. Giải phóng bộ nhớ khi tắt app (Rất quan trọng để tránh rò rỉ RAM)
  void dispose() {
    player.dispose();
  }
}