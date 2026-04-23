import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/track_model.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  List<TrackModel> _tracks = [];
  bool _isLoading = false;

  AudioPlayer get player => _player;
  List<TrackModel> get tracks => _tracks;
  bool get isLoading => _isLoading;

  /// Fetch playlist from Quran.com API and load it into the player.
  Future<void> fetchAndLoadPlaylist() async {
    _isLoading = true;
    try {
      // Fetch chapters for titles
      final chapterRes = await http.get(Uri.parse('https://api.quran.com/api/v4/chapters'));
      final Map<int, String> chapterNames = {};
      if (chapterRes.statusCode == 200) {
        final data = json.decode(chapterRes.body);
        for (var chapter in data['chapters']) {
          chapterNames[chapter['id']] = chapter['name_simple'];
        }
      }

      // Fetch audio files for a specific reciter (e.g., 1 = Mishary Alafasy)
      final audioRes = await http.get(Uri.parse('https://api.quran.com/api/v4/chapter_recitations/1'));
      if (audioRes.statusCode == 200) {
        final data = json.decode(audioRes.body);
        final List<dynamic> audioFiles = data['audio_files'];

        _tracks = audioFiles.take(20).map((json) {
          final id = json['chapter_id'] as int;
          json['name'] = chapterNames[id] ?? 'Chapter $id';
          return TrackModel.fromJson(json);
        }).toList();

        await _setupAudioSource();
      }
    } catch (e) {
      print('Error fetching playlist: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _setupAudioSource() async {
    final audioSource = ConcatenatingAudioSource(
      children: _tracks.map((track) {
        return AudioSource.uri(
          Uri.parse(track.url),
          tag: MediaItem(
            id: track.id.toString(),
            album: "Quran Recitation",
            title: track.title,
            artUri: Uri.parse(track.coverUrl),
          ),
        );
      }).toList(),
    );

    await _player.setAudioSource(audioSource);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> skipToNext() => _player.seekToNext();
  Future<void> skipToPrevious() => _player.seekToPrevious();
}
