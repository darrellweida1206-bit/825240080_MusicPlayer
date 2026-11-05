# Music Player - Flutter

Aplikasi Music Player menggunakan **Flutter dan iTunes Search API** untuk mencari lagu, melihat informasi lagu, serta mendengarkan preview audio.

## Fitur
- Pencarian lagu berdasarkan judul atau nama artis.
- Menampilkan cover album dan informasi detail lagu.
- Preview audio dengan Play/Pause dan slider.
- Pengurutan lagu A–Z.
- Dark Mode dan Light Mode.
- Loading, penanganan error, dan tampilan responsif.

## Teknologi
- Flutter (Dart)
- iTunes Search API
- Package `http` dan `audioplayers`

## Struktur Project
- `main.dart`: Halaman utama, pencarian API, dan pengaturan tema.
- `detail_page.dart`: Detail lagu dan pemutar preview.
- `song.dart`: Model data dan parsing JSON.

## Cara Menjalankan
1. Buka project di Android Studio.
2. Jalankan `flutter pub get` untuk menyiapkan dependencies.
3. Jalankan aplikasi menggunakan `flutter run`.