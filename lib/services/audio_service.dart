import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/track_model.dart';
import 'download_service.dart';
import 'quran_api_service.dart';
import 'firestore_service.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final DownloadService _downloadService;
  final FirestoreService _firestoreService;
  final QuranApiService _api = QuranApiService();

  List<TrackModel> _tracks = [];
  TrackModel? _currentTrack;
  bool _isLoading = false;
  bool _tracksLoaded = false;

  // Reciter state
  String _currentReciterId = '';
  String _currentReciterName = '';
  String _currentReciterShortName = '';
  List<Map<String, dynamic>> _reciters = [];

  // Verse text for current surah
  List<Map<String, dynamic>> _currentVerses = [];
  bool _versesLoading = false;

  // Stats tracking fields
  DateTime? _playStartTime;
  TrackModel? _trackedTrack;
  Timer? _syncTimer;

  AudioService(this._downloadService, this._firestoreService) {
    _initStatsTracking();
  }

  AudioPlayer get player => _player;
  List<TrackModel> get tracks => _tracks;
  TrackModel? get currentTrack => _currentTrack;
  bool get isLoading => _isLoading;
  bool get tracksLoaded => _tracksLoaded;
  bool get isPlaying => _player.playing;
  String get currentReciterName => _currentReciterName;
  String get currentReciterId => _currentReciterId;
  String get currentReciterShortName => _currentReciterShortName;
  List<Map<String, dynamic>> get reciters => _reciters;
  List<Map<String, dynamic>> get currentVerses => _currentVerses;
  bool get versesLoading => _versesLoading;

  /// Fetch all available reciters
  Future<void> fetchReciters() async {
    if (_reciters.isNotEmpty) return;
    try {
      _reciters = await _api.fetchReciters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching reciters: $e');
    }
  }

  /// Select a reciter and load their audio catalog
  Future<void> selectReciter(Map<String, dynamic> reciter) async {
    final id = reciter['reciter_id']?.toString() ?? '';
    final name = reciter['reciter_name']?.toString() ?? '';
    final shortName = reciter['reciter_short_name']?.toString() ?? '';

    if (id == _currentReciterId && _tracksLoaded) return;

    _currentReciterId = id;
    _currentReciterName = name;
    _currentReciterShortName = shortName;
    _isLoading = true;
    _tracksLoaded = false;
    notifyListeners();

    try {
      final data = await _api.fetchReciterAudio(id);
      final List<dynamic> audioUrls = data['audio_urls'] ?? [];

      _tracks = audioUrls
          .map((json) => TrackModel.fromReciterAudio(
                json as Map<String, dynamic>,
                name,
              ))
          .toList();

      _tracksLoaded = true;
    } catch (e) {
      debugPrint('Error loading reciter audio: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Play a specific surah by its ID
  Future<void> playSurah(int surahId) async {
    if (!_tracksLoaded || _tracks.isEmpty) return;

    final track = _tracks.firstWhere(
      (t) => t.id == surahId,
      orElse: () => _tracks.first,
    );

    _currentTrack = track;
    notifyListeners();

    // Load verses in background
    _loadVersesForSurah(surahId);

    try {
      final localPath = await _downloadService.getLocalUri(surahId);

      final audioSource = AudioSource.uri(
        localPath != null ? Uri.file(localPath) : Uri.parse(track.url),
        tag: MediaItem(
          id: track.id.toString(),
          album: "Quran - $_currentReciterName",
          title: track.title,
          artUri: Uri.parse(track.coverUrl),
        ),
      );

      await _player.setAudioSource(audioSource);
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing surah $surahId: $e');
    }
  }

  /// Play from a specific surah and build a playlist from that point
  Future<void> playSurahWithPlaylist(int surahId) async {
    if (!_tracksLoaded || _tracks.isEmpty) return;

    final startIndex = _tracks.indexWhere((t) => t.id == surahId);
    if (startIndex < 0) {
      await playSurah(surahId);
      return;
    }

    _currentTrack = _tracks[startIndex];
    notifyListeners();

    _loadVersesForSurah(surahId);

    try {
      final sources = <AudioSource>[];
      for (final track in _tracks) {
        final localPath = await _downloadService.getLocalUri(track.id);
        sources.add(AudioSource.uri(
          localPath != null ? Uri.file(localPath) : Uri.parse(track.url),
          tag: MediaItem(
            id: track.id.toString(),
            album: "Quran - $_currentReciterName",
            title: track.title,
            artUri: Uri.parse(track.coverUrl),
          ),
        ));
      }

      // ignore: deprecated_member_use
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: startIndex,
      );
      await _player.play();

      // Listen for track changes to update verses
      _player.currentIndexStream.listen((index) {
        if (index != null && index < _tracks.length) {
          _currentTrack = _tracks[index];
          _loadVersesForSurah(_tracks[index].id);
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error playing playlist: $e');
    }
  }

  /// Load verse text for a surah (for display in expanded player)
  Future<void> _loadVersesForSurah(int surahId) async {
    _versesLoading = true;
    _currentVerses = [];
    notifyListeners();

    try {
      List<Map<String, dynamic>> allAyahs = [];
      bool foundSurah = false;
      bool finishedSurah = false;

      int startPage = getSurahStartPage(surahId);

      for (int page = startPage; page <= 604 && !finishedSurah; page++) {
        final response = await _api.fetchPageText(page);
        if (response['code'] == 200) {
          final data = response['data'];
          final ayahs = (data['ayahs'] as List).cast<Map<String, dynamic>>();

          for (var ayah in ayahs) {
            final surahNum = int.parse(ayah['surah']['number'].toString());
            if (surahNum == surahId) {
              foundSurah = true;
              allAyahs.add(ayah);
            } else if (foundSurah) {
              finishedSurah = true;
              break;
            }
          }
          if (!foundSurah && page > startPage + 15) break;
        }
      }

      _currentVerses = allAyahs;
    } catch (e) {
      debugPrint('Error loading verses for surah $surahId: $e');
    } finally {
      _versesLoading = false;
      notifyListeners();
    }
  }

  TrackModel? getTrackBySurahId(int surahId) {
    try {
      return _tracks.firstWhere((t) => t.id == surahId);
    } catch (_) {
      return null;
    }
  }

  Future<void> play() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> skipToNext() async {
    await _player.seekToNext();
    _updateCurrentTrack();
  }

  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    _updateCurrentTrack();
  }

  void _updateCurrentTrack() {
    final index = _player.currentIndex;
    if (index != null && index < _tracks.length) {
      _currentTrack = _tracks[index];
      _loadVersesForSurah(_currentTrack!.id);
      notifyListeners();
    }
  }

  int getSurahStartPage(int surahNumber) {
    const Map<int, int> startPages = {
      1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177,
      9: 187, 10: 208, 11: 221, 12: 235, 13: 249, 14: 255, 15: 262,
      16: 267, 17: 282, 18: 293, 19: 305, 20: 312, 21: 322, 22: 332,
      23: 342, 24: 350, 25: 359, 26: 367, 27: 377, 28: 385, 29: 396,
      30: 404, 31: 411, 32: 415, 33: 418, 34: 428, 35: 434, 36: 440,
      37: 446, 38: 453, 39: 458, 40: 467, 41: 477, 42: 483, 43: 489,
      44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515, 50: 518,
      51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537,
      58: 542, 59: 545, 60: 549, 61: 551, 62: 553, 63: 554, 64: 556,
      65: 558, 66: 560, 67: 562, 68: 564, 69: 566, 70: 568, 71: 570,
      72: 572, 73: 574, 74: 575, 75: 577, 76: 578, 77: 580, 78: 582,
      79: 583, 80: 585, 81: 586, 82: 587, 83: 587, 84: 589, 85: 590,
      86: 591, 87: 591, 88: 592, 89: 593, 90: 594, 91: 595, 92: 595,
      93: 596, 94: 596, 95: 597, 96: 597, 97: 598, 98: 598, 99: 599,
      100: 599, 101: 600, 102: 600, 103: 601, 104: 601, 105: 601,
      106: 602, 107: 602, 108: 602, 109: 603, 110: 603, 111: 603,
      112: 604, 113: 604, 114: 604,
    };
    return startPages[surahNumber] ?? 1;
  }

  void _initStatsTracking() {
    // Listen to play/pause state changes
    _player.playingStream.listen((playing) {
      _handlePlayStateChange(playing);
    });

    // Listen to track changes
    _player.currentIndexStream.listen((index) {
      _handleTrackChange(index);
    });

    // Periodic sync every 30 seconds of continuous play to prevent data loss
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_player.playing && _playStartTime != null && _trackedTrack != null) {
        final elapsed = DateTime.now().difference(_playStartTime!).inSeconds;
        if (elapsed >= 30) {
          _firestoreService.updateListeningStats(
            surahId: _trackedTrack!.id,
            surahName: _trackedTrack!.title,
            additionalSeconds: elapsed,
            isNewPlay: false,
          );
          _playStartTime = DateTime.now(); // Reset start time to current sync timestamp
        }
      }
    });
  }

  void _handlePlayStateChange(bool playing) {
    if (playing) {
      // Audio started playing
      _playStartTime = DateTime.now();
      _trackedTrack = _currentTrack;
      if (_trackedTrack != null) {
        _firestoreService.updateListeningStats(
          surahId: _trackedTrack!.id,
          surahName: _trackedTrack!.title,
          additionalSeconds: 0,
          isNewPlay: true,
        );
      }
    } else {
      // Audio paused or stopped
      _syncAccumulatedTime();
    }
  }

  void _handleTrackChange(int? index) {
    if (_player.playing) {
      // Sync accumulated time for the previous track before starting the new one
      _syncAccumulatedTime();
      _playStartTime = DateTime.now();
      _trackedTrack = _currentTrack;
      if (_trackedTrack != null) {
        _firestoreService.updateListeningStats(
          surahId: _trackedTrack!.id,
          surahName: _trackedTrack!.title,
          additionalSeconds: 0,
          isNewPlay: true,
        );
      }
    }
  }

  void _syncAccumulatedTime() {
    if (_playStartTime != null && _trackedTrack != null) {
      final elapsed = DateTime.now().difference(_playStartTime!).inSeconds;
      if (elapsed > 0) {
        _firestoreService.updateListeningStats(
          surahId: _trackedTrack!.id,
          surahName: _trackedTrack!.title,
          additionalSeconds: elapsed,
          isNewPlay: false,
        );
      }
      _playStartTime = null;
      _trackedTrack = null;
    }
  }

  @override
  void dispose() {
    _syncAccumulatedTime();
    _syncTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
