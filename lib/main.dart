import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'services/audio_manager.dart';
import 'models/song.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, primaryColor: Colors.deepPurple),
      // Kiểm tra xem đã đăng nhập chưa
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH ĐĂNG NHẬP & ĐĂNG KÝ (FULL TÍNH NĂNG)
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true; // Biến để lật qua lật lại giữa Đăng nhập và Đăng ký
  bool _isLoading = false; // Biến để xoay vòng chờ tải

  // Hàm xử lý chung cho cả Đăng nhập & Đăng ký
  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Kiểm tra không được để trống
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đầy đủ Email và Mật khẩu!")));
      return;
    }

    // 2. Kiểm tra độ dài mật khẩu (Fix điểm mù số 1)
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu phải dài ít nhất 6 ký tự!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Gọi Firebase Đăng nhập
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // Gọi Firebase Đăng ký mới
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }
      // Không cần dùng Navigator chuyển trang, vì StreamBuilder ở MyApp sẽ tự động đá người dùng sang HomeScreen!
    } on FirebaseAuthException catch (e) {
      // 3. Bắt các lỗi từ máy chủ Firebase (Fix điểm mù số 2)
      String message = "Đã có lỗi xảy ra!";
      if (e.code == 'user-not-found') message = "Không tìm thấy tài khoản với email này.";
      else if (e.code == 'wrong-password') message = "Mật khẩu không chính xác.";
      else if (e.code == 'email-already-in-use') message = "Email này đã được đăng ký từ trước.";
      else if (e.code == 'invalid-email') message = "Định dạng Email không hợp lệ.";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 100, color: Colors.deepPurpleAccent),
              const SizedBox(height: 20),
              Text(_isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ TÀI KHOẢN", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              // Ô nhập Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              
              // Ô nhập Mật khẩu
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu (tối thiểu 6 ký tự)',
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 30),
              
              // Nút Bấm chính
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : _submitAuth,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(_isLogin ? "Đăng nhập" : "Tạo tài khoản", style: const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 15),
              
              // Nút lật sang Đăng nhập/Đăng ký
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin; // Đảo ngược trạng thái
                  });
                },
                child: Text(
                  _isLogin ? "Chưa có tài khoản? Đăng ký ngay" : "Đã có tài khoản? Đăng nhập",
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ==========================================
// MÀN HÌNH CHÍNH (TÍCH HỢP TAB YÊU THÍCH)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = "";
  int _selectedIndex = 0; // Biến kiểm soát đang ở Tab nào (0: Khám phá, 1: Yêu thích)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Tiêu đề thay đổi linh hoạt theo Tab
        title: Text(_selectedIndex == 0 ? "Khám phá" : "Nhạc Yêu Thích", style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())
        ],
      ),
      body: Column(
        children: [
          // THANH TÌM KIẾM (Chỉ cho phép hiện diện ở tab Khám phá)
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Tìm bài hát...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true, fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            
          // KHU VỰC HIỂN THỊ DANH SÁCH NHẠC (Sẽ tráo đổi qua lại tùy biến _selectedIndex)
          Expanded(
            child: _selectedIndex == 0 ? _buildAllSongs() : _buildFavoriteSongs(),
          ),
        ],
      ),
      
      // THANH ĐIỀU HƯỚNG DƯỚI ĐÁY
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Cập nhật lại giao diện khi bấm tab
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: "Khám phá"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Yêu thích"),
        ],
      ),
    );
  }

  // ===============================================
  // HÀM 1: Lấy toàn bộ nhạc từ kho chung (Tab 0)
  // ===============================================
  Widget _buildAllSongs() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('songs').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var songs = snapshot.data!.docs
            .map((doc) => Song.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .where((s) => s.title.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        return _buildSongListView(songs);
      },
    );
  }

  // ===============================================
  // HÀM 2: Lấy nhạc Yêu thích của riêng User (Tab 1)
  // ===============================================
  Widget _buildFavoriteSongs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Vui lòng đăng nhập"));

    return StreamBuilder<QuerySnapshot>(
      // Chọc đúng vào kho dữ liệu cá nhân của người dùng hiện tại
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var songs = snapshot.data!.docs
            .map((doc) => Song.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        // Xử lý "Góc khuất" giao diện trống
        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.heart_broken, size: 80, color: Colors.grey[800]),
                const SizedBox(height: 16),
                const Text("Chưa có bài hát yêu thích nào!", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return _buildSongListView(songs);
      },
    );
  }

  // ===============================================
  // HÀM 3: Giao diện vẽ từng dòng bài hát (Dùng chung cho cả 2 Tab)
  // ===============================================
  Widget _buildSongListView(List<Song> songs) {
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(imageUrl: song.artUri, width: 50, height: 50, fit: BoxFit.cover),
          ),
          title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(song.artist, style: const TextStyle(color: Colors.grey)),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
            AudioManager.instance.initPlaylist(songs, initialIndex: index).then((_) {
              AudioManager.instance.player.play();
            });
          },
        );
      },
    );
  }
}

// ==========================================
// MÀN HÌNH PHÁT NHẠC (BẢN HOÀN CHỈNH REAL-TIME & TOGGLE LIKE)
// ==========================================
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = AudioManager.instance.player;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 35),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Đang phát", style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. THÔNG TIN BÀI HÁT
            StreamBuilder<SequenceState?>(
              stream: player.sequenceStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state == null || state.sequence.isEmpty) return const SizedBox();
                final song = state.currentSource!.tag as Song;

                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: song.artUri,
                        width: MediaQuery.of(context).size.width - 48,
                        height: MediaQuery.of(context).size.width - 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text(song.artist, style: const TextStyle(fontSize: 18, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        // ==============================================
                        // NÚT THẢ TIM (REAL-TIME STREAM & TOGGLE LOGIC)
                        // ==============================================
                        StreamBuilder<DocumentSnapshot>(
                          // Lắng nghe xem bài hát này đã được user thích chưa trong Real-time
                          stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).collection('favorites').doc(song.id).snapshots(),
                          builder: (context, favSnapshot) {
                            // Biến kiểm tra xem tài liệu yêu thích có tồn tại hay không
                            bool isLiked = favSnapshot.data?.exists ?? false;

                            return IconButton(
                              // ĐIỀU CHỈNH BIỂU TƯỢNG ĐỘNG (DỌN LỖI)
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border, // Nếu thích -> Hiện tim full; Ngược lại -> Hiện tim viền
                                color: Colors.red,
                                size: 30
                              ),
                              onPressed: () {
                                final user = FirebaseAuth.instance.currentUser;
                                final docRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('favorites').doc(song.id);
                                
                                if (isLiked) {
                                  // LOGIC "BỎ THÍCH" (Dislike)
                                  docRef.delete();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã bỏ khỏi Playlist yêu thích!")));
                                } else {
                                  // LOGIC "THÍCH" (Like)
                                  docRef.set({
                                    'title': song.title,
                                    'artist': song.artist,
                                    'artUri': song.artUri,
                                    'url': song.url,
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm vào Playlist yêu thích!")));
                                }
                              },
                            );
                          },
                        ),
                        // ==============================================
                      ],
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 40),

            // 2. THANH PROGRESS BAR TỪ THƯ VIỆN
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: player.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: player.bufferedPositionStream,
                      builder: (context, bufferedSnapshot) {
                        final buffered = bufferedSnapshot.data ?? Duration.zero;
                        return ProgressBar(
                          progress: position,
                          buffered: buffered,
                          total: duration,
                          progressBarColor: Colors.deepPurpleAccent,
                          baseBarColor: Colors.grey[800],
                          bufferedBarColor: Colors.grey[600],
                          thumbColor: Colors.deepPurpleAccent,
                          onSeek: (duration) => player.seek(duration),
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // 3. CÁC NÚT ĐIỀU KHIỂN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 40),
                  onPressed: () => player.seekToPrevious(),
                ),
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;
                    
                    if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                      return Container(margin: const EdgeInsets.all(8.0), width: 64.0, height: 64.0, child: const CircularProgressIndicator(color: Colors.deepPurpleAccent));
                    } else if (playing != true) {
                      return IconButton(icon: const Icon(Icons.play_circle_fill), iconSize: 80, color: Colors.deepPurpleAccent, onPressed: player.play);
                    } else if (processingState != ProcessingState.completed) {
                      return IconButton(icon: const Icon(Icons.pause_circle_filled), iconSize: 80, color: Colors.deepPurpleAccent, onPressed: player.pause);
                    } else {
                      return IconButton(icon: const Icon(Icons.replay_circle_filled), iconSize: 80, color: Colors.deepPurpleAccent, onPressed: () => player.seek(Duration.zero));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 40),
                  onPressed: () => player.seekToNext(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}