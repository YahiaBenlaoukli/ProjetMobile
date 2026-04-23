class TrackModel {
  final int id;
  final String title;
  final String url;
  final String coverUrl;

  TrackModel({
    required this.id,
    required this.title,
    required this.url,
    required this.coverUrl,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['chapter_id'] as int,
      title: json['name'] ?? 'Chapter ${json['chapter_id']}',
      url: _buildAudioUrl(json['audio_url'] as String),
      coverUrl: 'https://cdn.pixabay.com/photo/2023/04/10/12/36/quran-7913706_1280.jpg', // Dummy cover
    );
  }

  static String _buildAudioUrl(String path) {
    if (path.startsWith('http')) return path;
    return 'https://verses.quran.com/$path';
  }
}
