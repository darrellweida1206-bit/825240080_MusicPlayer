class Song {
  final String trackName;
  final String artistName;
  final String collectionName;
  final String primaryGenreName;
  final String releaseDate;
  final String artworkUrl100;
  final String previewUrl;
  final int trackTimeMillis;

  Song({
    required this.trackName,
    required this.artistName,
    required this.collectionName,
    required this.primaryGenreName,
    required this.releaseDate,
    required this.artworkUrl100,
    required this.previewUrl,
    required this.trackTimeMillis,
  });

  // Mengubah data JSON menjadi objek Song
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      trackName: (json['trackName'] ?? '-').toString(),
      artistName: (json['artistName'] ?? '-').toString(),
      collectionName: (json['collectionName'] ?? '-').toString(),
      primaryGenreName: (json['primaryGenreName'] ?? '-').toString(),
      releaseDate: (json['releaseDate'] ?? '-')
          .toString()
          .split('T')[0],
      artworkUrl100: (json['artworkUrl100'] ?? '').toString(),
      previewUrl: (json['previewUrl'] ?? '').toString(),
      trackTimeMillis: json['trackTimeMillis'] is num
          ? (json['trackTimeMillis'] as num).toInt()
          : 0,
    );
  }

  // Mengambil cover album resolusi lebih besar
  String get artworkLarge =>
      artworkUrl100.replaceAll('100x100', '600x600');
}
