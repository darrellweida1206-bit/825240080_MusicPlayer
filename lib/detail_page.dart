import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'song.dart';

// HALAMAN DETAIL LAGU
class DetailPage extends StatefulWidget {
  final Song song;

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

    // Memperbarui posisi pemutaran
    player.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          posisi = p;
        });
      }
    });

    // Memperbarui durasi preview
    player.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          total = d;
        });
      }
    });

    // Mengatur posisi ketika lagu selesai
    player.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          posisi = Duration.zero;
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
        final url = widget.song.previewUrl;

        if (url.isNotEmpty) {
          await player.play(UrlSource(url));
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

  // Mengubah durasi menjadi menit:detik
  String format(Duration d) {
    final menit = d.inMinutes;
    final detik = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  // Menampilkan satu baris informasi lagu
  Widget infoBaris(String label, String isi) {
    final dark = Theme.of(context).brightness == Brightness.dark;

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
                color: dark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isi,
              style: TextStyle(fontWeight: FontWeight.w500),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hijau = Theme.of(context).colorScheme.primary;

    final warnaCard = dark
        ? Color(0xFF242424)
        : Color(0xFFEAF5ED);

    final warnaSekunder = dark ? Colors.white70 : Colors.black54;

    // Ukuran cover responsif maksimal 350 px
    final ukuranCover = (MediaQuery.of(context).size.width * 0.8)
        .clamp(0.0, 350.0);

    final durasiMax = total.inSeconds > 0
        ? total.inSeconds.toDouble()
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Lagu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cover album di tengah
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.song.artworkLarge,
                      width: ukuranCover,
                      height: ukuranCover,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          Icon(Icons.music_note, size: 150),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Judul dan artis
                Text(
                  widget.song.trackName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  widget.song.artistName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: warnaSekunder,
                  ),
                ),

                SizedBox(height: 28),

                // Kotak informasi lagu
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: warnaCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      infoBaris(
                        'Album',
                        widget.song.collectionName,
                      ),
                      Divider(),
                      infoBaris(
                        'Genre',
                        widget.song.primaryGenreName,
                      ),
                      Divider(),
                      infoBaris(
                        'Rilis',
                        widget.song.releaseDate,
                      ),
                      Divider(),
                      infoBaris(
                        'Durasi',
                        format(Duration(
                          milliseconds: widget.song.trackTimeMillis,
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

                // Slider pemutaran lagu
                Slider(
                  activeColor: hijau,
                  inactiveColor: dark
                      ? Colors.white24
                      : Colors.black12,
                  value: posisi.inSeconds.toDouble().clamp(
                    0.0,
                    durasiMax,
                  ),
                  max: durasiMax,
                  onChanged: total.inSeconds > 0
                      ? (value) {
                    player.seek(
                      Duration(seconds: value.toInt()),
                    );
                  }
                      : null,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      format(posisi),
                      style: TextStyle(color: warnaSekunder),
                    ),
                    Text(
                      format(total),
                      style: TextStyle(color: warnaSekunder),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Tombol Play/Pause
                IconButton(
                  iconSize: 70,
                  color: hijau,
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
