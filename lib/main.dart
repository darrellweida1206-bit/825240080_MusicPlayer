import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'song.dart';
import 'detail_page.dart';

const Color hijau = Color(0xFF1DB954);

void main() {
  runApp(const MusicApp());
}

// Mengatur Dark Mode dan Light Mode
class MusicApp extends StatefulWidget {
  const MusicApp({super.key});

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  bool gelap = true;

  ThemeData buatTema(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: hijau,
        brightness: brightness,
      ).copyWith(primary: hijau),
      scaffoldBackgroundColor: dark
          ? Color(0xFF121212)
          : Color(0xFFF7F8F7),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? Color(0xFF121212)
            : Colors.white,
        foregroundColor: dark
            ? Colors.white
            : Color(0xFF171717),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buatTema(Brightness.light),
      darkTheme: buatTema(Brightness.dark),
      themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
      home: MyApp(
        isDarkMode: gelap,
        onToggleTema: () {
          setState(() {
            gelap = !gelap;
          });
        },
      ),
    );
  }
}

// HALAMAN UTAMA
class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTema;

  const MyApp({
    super.key,
    required this.isDarkMode,
    required this.onToggleTema,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = TextEditingController();

  List<Song> songs = [];
  bool loading = false;
  bool sudahCari = false;
  bool urutAZ = false;
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
      sudahCari = false;
      songs = [];
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
      final response = await http.get(url).timeout(
        Duration(seconds: 15),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List hasil = data['results'] ?? [];

        setState(() {
          // Mengubah hasil JSON menjadi List Song
          songs = hasil
              .map((item) => Song.fromJson(item))
              .toList();
          sudahCari = true;
        });
      } else {
        setState(() {
          songs = [];
          sudahCari = true;
          pesanError =
          'Gagal mengambil data lagu (HTTP ${response.statusCode})';
        });
      }
    } catch (e) {
      debugPrint('Error: $e');

      if (mounted) {
        setState(() {
          songs = [];
          sudahCari = true;
          pesanError =
          'Gagal memuat lagu. Periksa koneksi internet Anda.';
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    final warnaCard = dark ? Color(0xFF242424) : Colors.white;
    final warnaSekunder = dark ? Colors.white70 : Colors.black54;

    // Mengurutkan lagu A-Z jika diaktifkan
    final daftarLagu = List<Song>.from(songs);

    if (urutAZ) {
      daftarLagu.sort(
            (a, b) => a.trackName.toLowerCase().compareTo(
          b.trackName.toLowerCase(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Music Player',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Tombol Dark/Light Mode
          IconButton(
            tooltip: widget.isDarkMode
                ? 'Light Mode'
                : 'Dark Mode',
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: hijau,
            ),
            onPressed: widget.onToggleTema,
          ),
          SizedBox(width: 8),
        ],
      ),

      // Lebar halaman dibatasi agar responsif
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 650),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 8),

                // Kolom pencarian lagu
                TextField(
                  controller: controller,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Judul lagu atau artis',
                    prefixIcon: Icon(Icons.search),

                    // Tombol menghapus teks
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                    )
                        : null,

                    filled: true,
                    fillColor: warnaCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: hijau,
                        width: 2,
                      ),
                    ),
                    floatingLabelStyle: TextStyle(color: hijau),
                  ),
                  onSubmitted: (_) {
                    if (!loading) cariLagu();
                  },
                ),

                SizedBox(height: 14),

                // Tombol mencari lagu
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hijau,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: loading ? null : cariLagu,
                    icon: Icon(Icons.search),
                    label: Text(
                      'Cari Lagu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Loading
                if (loading)
                  CircularProgressIndicator(color: hijau),

                // Pesan error
                if (!loading && pesanError.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      pesanError,
                      style: TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Pesan ketika lagu tidak ditemukan
                if (!loading &&
                    pesanError.isEmpty &&
                    sudahCari &&
                    songs.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Lagu tidak ditemukan',
                      style: TextStyle(color: warnaSekunder),
                    ),
                  ),

                // Jumlah hasil dan pengurutan A-Z
                if (!loading && songs.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hasil Pencarian (${songs.length} lagu)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            urutAZ = !urutAZ;
                          });
                        },
                        icon: Icon(
                          Icons.sort_by_alpha,
                          color: hijau,
                        ),
                        label: Text(
                          urutAZ ? 'Default' : 'A-Z',
                          style: TextStyle(
                            color: hijau,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 8),

                // Menampilkan daftar lagu
                Expanded(
                  child: ListView.builder(
                    itemCount: daftarLagu.length,
                    itemBuilder: (context, index) {
                      final lagu = daftarLagu[index];

                      return Card(
                        color: warnaCard,
                        elevation: 0,
                        margin: EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              lagu.artworkUrl100,
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  Icon(Icons.music_note, size: 40),
                            ),
                          ),
                          title: Text(
                            lagu.trackName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            lagu.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: warnaSekunder),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: hijau,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPage(
                                  song: lagu,
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
