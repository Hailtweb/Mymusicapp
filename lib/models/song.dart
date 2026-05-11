class Song {
  final String id;
  final String title;
  final String artist;
  final String artUri;
  final String url;
  bool isLiked; 

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artUri,
    required this.url,
    this.isLiked = false,
  });

  // Chuyển dữ liệu từ Firestore về Object
  factory Song.fromFirestore(Map<String, dynamic> data, String id) {
    return Song(
      id: id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      artUri: data['artUri'] ?? '',
      url: data['url'] ?? '',
    );
  }
}

// MỘT VÀI BÀI HÁT MẪU (DÙNG LINK PUBLIC MIỄN PHÍ ĐỂ TEST)
final List<Song> playlistData = [
  Song(
    id: '1',
    title: 'Bản nhạc Nhẹ nhàng 1',
    artist: 'SoundHelix',
    artUri: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  ),
  Song(
    id: '2',
    title: 'Giai điệu Sôi động 2',
    artist: 'SoundHelix',
    artUri: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
  ),
  Song(
    id: '3',
    title: 'Âm hưởng Bình yên 3',
    artist: 'SoundHelix',
    artUri: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  ),
];