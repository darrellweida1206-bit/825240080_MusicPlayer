
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = TextEditingController();
  List songs = [];
  bool loading = false;
  bool sudahCari = false;
  String pesanError = '';

  // Mengambil data lagu dari iTunes API
  Future<void> cariLagu() async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masukkan judul lagu atau artis')),
      );
      return;
    }

    setState(() {
      loading = true;
      pesanError = '';
    });

    final url = Uri.https(
      'itunes.apple.com',
      '/search',
      <String, String>{
        'term': controller.text.trim(),
        'limit': '10',
        'entity': 'song',
      },
    );

    try {
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          songs = data['results'] ?? [];
          sudahCari = true;
        });
      } else {
        setState(() {
          songs = [];
          sudahCari = true;
          pesanError = 'Gagal mengambil data lagu';
        });
      }
    } catch (e) {
      debugPrint('Error: $e');

      if (mounted) {
        setState(() {
          songs = [];
          sudahCari = true;
          pesanError = 'Periksa koneksi internet Anda';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music Player'),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
      ),

      // Membatasi lebar pencarian pada layar komputer
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 650),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Judul lagu atau artis',
                    prefixIcon: Icon(Icons.search),

                    // Tombol menghapus teks pencarian
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                    )
                        : null,

                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.lightGreen,
                        width: 2,
                      ),
                    ),
                    floatingLabelStyle: TextStyle(
                      color: Colors.lightGreen,
                    ),
                  ),
                  onSubmitted: (_) => cariLagu(),
                ),

                SizedBox(height: 12),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: loading ? null : cariLagu,
                  child: Text('Cari Lagu'),
                ),

                SizedBox(height: 16),

                if (loading)
                  CircularProgressIndicator(
                    color: Colors.lightGreen,
                  ),

                if (!loading && pesanError.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      pesanError,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (!loading &&
                    pesanError.isEmpty &&
                    sudahCari &&
                    songs.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Lagu tidak ditemukan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                if (!loading && songs.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hasil Pencarian (${songs.length} lagu)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              songs[index]['artworkUrl100'] ?? '',
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  Icon(Icons.music_note),
                            ),
                          ),
                          title: Text(
                            songs[index]['trackName'] ?? '-',
                          ),
                          subtitle: Text(
                            songs[index]['artistName'] ?? '-',
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.lightGreen,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPage(
                                  song: songs[index],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// HALAMAN DETAIL LAGU
class DetailPage extends StatefulWidget {
  final Map song;

  const DetailPage({super.key, required this.song});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final player = AudioPlayer();
  bool isPlaying = false;
  Duration posisi = Duration.zero;
  Duration total = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Memperbarui tombol Play/Pause
    player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Memperbarui posisi dan durasi preview
    player.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          posisi = p;
        });
      }
    });

    player.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          total = d;
        });
      }
    });
  }

  // Mengatur pemutaran lagu
  Future<void> tombolPlay() async {
    try {
      if (isPlaying) {
        await player.pause();
      } else if (player.state == PlayerState.paused) {
        await player.resume();
      } else {
        final url = widget.song['previewUrl'];

        if (url != null && url.toString().isNotEmpty) {
          await player.play(UrlSource(url.toString()));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Preview tidak tersedia')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Audio Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memutar lagu')),
        );
      }
    }
  }

  // Mengubah durasi menjadi format menit:detik
  String format(Duration d) {
    final menit = d.inMinutes;
    final detik = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  // Menampilkan satu baris informasi lagu
  Widget infoBaris(String label, String isi) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isi,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gambar = (widget.song['artworkUrl100'] ?? '')
        .toString()
        .replaceAll('100x100', '600x600');

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Lagu'),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 40, 24, 24),

        // Membatasi lebar konten detail pada layar komputer
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cover album tetap di tengah
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      gambar,
                      width: (MediaQuery.of(context).size.width * 0.8)
                          .clamp(0.0, 350.0),
                      height: (MediaQuery.of(context).size.width * 0.8)
                          .clamp(0.0, 350.0),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          Icon(Icons.music_note, size: 150),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Judul lagu dan nama artis
                Text(
                  widget.song['trackName'] ?? '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  widget.song['artistName'] ?? '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey.shade700,
                  ),
                ),

                SizedBox(height: 24),

                // Kotak informasi lagu
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      infoBaris(
                        'Album',
                        widget.song['collectionName'] ?? '-',
                      ),
                      Divider(),
                      infoBaris(
                        'Genre',
                        widget.song['primaryGenreName'] ?? '-',
                      ),
                      Divider(),
                      infoBaris(
                        'Rilis',
                        (widget.song['releaseDate'] ?? '-')
                            .toString()
                            .split('T')[0],
                      ),
                      Divider(),
                      infoBaris(
                        'Durasi',
                        format(Duration(
                          milliseconds:
                          widget.song['trackTimeMillis'] ?? 0,
                        )),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 28),

                Text(
                  'Preview Lagu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12),

                // Progress pemutaran preview
                Slider(
                  activeColor: Colors.lightGreen,
                  inactiveColor: Colors.lightGreen.shade100,
                  value: posisi.inSeconds.toDouble().clamp(
                    0.0,
                    total.inSeconds > 0
                        ? total.inSeconds.toDouble()
                        : 1.0,
                  ),
                  max: total.inSeconds > 0
                      ? total.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    player.seek(
                      Duration(seconds: value.toInt()),
                    );
                  },
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(format(posisi)),
                    Text(format(total)),
                  ],
                ),

                SizedBox(height: 12),

                // Tombol Play/Pause tetap seperti kode awal
                IconButton(
                  iconSize: 70,
                  color: Colors.lightGreen,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  onPressed: tombolPlay,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
