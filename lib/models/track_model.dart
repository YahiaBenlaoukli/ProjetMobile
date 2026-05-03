class TrackModel {
  final int id;
  final String title;
  final String titleAr;
  final String url;
  final String coverUrl;
  final String reciterName;

  TrackModel({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.url,
    required this.coverUrl,
    required this.reciterName,
  });

  /// Factory from quran.com API response
  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['chapter_id'] as int,
      title: json['name'] ?? 'Chapter ${json['chapter_id']}',
      titleAr: json['name_ar'] ?? '',
      url: _buildAudioUrl(json['audio_url'] as String),
      coverUrl: 'https://cdn.pixabay.com/photo/2023/04/10/12/36/quran-7913706_1280.jpg',
      reciterName: json['reciter_name'] ?? 'Mishary Alafasy',
    );
  }

  /// Factory from yousefheiba reciterAudio API
  factory TrackModel.fromReciterAudio(
    Map<String, dynamic> json,
    String reciterName,
  ) {
    final surahId = int.parse(json['surah_id'].toString());
    return TrackModel(
      id: surahId,
      title: json['surah_name_ar'] ?? 'سورة $surahId',
      titleAr: json['surah_name_ar'] ?? '',
      url: json['audio_url'] ?? '',
      coverUrl: 'https://cdn.pixabay.com/photo/2023/04/10/12/36/quran-7913706_1280.jpg',
      reciterName: reciterName,
    );
  }

  static String _buildAudioUrl(String path) {
    if (path.startsWith('http')) return path;
    return 'https://verses.quran.com/$path';
  }
}
