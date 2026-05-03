import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum DownloadState { none, downloading, completed, failed }

class DownloadInfo {
  final DownloadState state;
  final double progress;
  DownloadInfo({required this.state, this.progress = 0.0});
}

class DownloadService extends ChangeNotifier {
  final Map<int, DownloadInfo> _downloads = {};

  DownloadInfo getStatus(int surahId) {
    return _downloads[surahId] ?? DownloadInfo(state: DownloadState.none);
  }

  /// Check if a surah audio is already downloaded
  Future<bool> isDownloaded(int surahId) async {
    final path = await _getFilePath(surahId);
    return File(path).existsSync();
  }

  /// Get the local file path for a surah
  Future<String> _getFilePath(int surahId) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/quran_audio');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }
    return '${audioDir.path}/surah_$surahId.mp3';
  }

  /// Get the local URI if downloaded, null otherwise
  Future<String?> getLocalUri(int surahId) async {
    final path = await _getFilePath(surahId);
    if (File(path).existsSync()) return path;
    return null;
  }

  /// Download a surah audio file
  Future<void> downloadSurah(int surahId, String url) async {
    if (_downloads[surahId]?.state == DownloadState.downloading) return;

    _downloads[surahId] = DownloadInfo(
      state: DownloadState.downloading,
      progress: 0.0,
    );
    notifyListeners();

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      final contentLength = response.contentLength ?? 0;
      final filePath = await _getFilePath(surahId);
      final file = File(filePath);
      final sink = file.openWrite();

      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          _downloads[surahId] = DownloadInfo(
            state: DownloadState.downloading,
            progress: received / contentLength,
          );
          notifyListeners();
        }
      }
      await sink.close();

      _downloads[surahId] = DownloadInfo(
        state: DownloadState.completed,
        progress: 1.0,
      );
      notifyListeners();
    } catch (e) {
      _downloads[surahId] = DownloadInfo(state: DownloadState.failed);
      notifyListeners();
      debugPrint('Download error for surah $surahId: $e');
    }
  }

  /// Delete a downloaded surah
  Future<void> deleteSurah(int surahId) async {
    final path = await _getFilePath(surahId);
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
    _downloads[surahId] = DownloadInfo(state: DownloadState.none);
    notifyListeners();
  }

  /// Initialize download states by checking local files
  Future<void> initializeStates(List<int> surahIds) async {
    for (final id in surahIds) {
      final downloaded = await isDownloaded(id);
      if (downloaded) {
        _downloads[id] = DownloadInfo(
          state: DownloadState.completed,
          progress: 1.0,
        );
      }
    }
    notifyListeners();
  }
}
