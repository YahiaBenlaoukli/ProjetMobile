import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranApiService {
  static const String _baseUrl = 'https://quran.yousefheiba.com/api';

  /// Fetch all 114 surahs
  Future<List<Map<String, dynamic>>> fetchSurahs() async {
    final response = await http.get(Uri.parse('$_baseUrl/surahs'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load surahs');
  }

  /// Fetch Quran page text (page 1-604)
  Future<Map<String, dynamic>> fetchPageText(int pageNumber) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/quranPagesText?page=$pageNumber'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load page $pageNumber');
  }

  /// Get Quran page image URL (page 1-604)
  String getPageImageUrl(int pageNumber) {
    return '$_baseUrl/quranPagesImage?page=$pageNumber';
  }

  /// Fetch all reciters
  Future<List<Map<String, dynamic>>> fetchReciters() async {
    final response = await http.get(Uri.parse('$_baseUrl/reciters'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> reciters = data['reciters'] ?? [];
      return reciters.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load reciters');
  }

  /// Fetch all audio URLs for a specific reciter
  Future<Map<String, dynamic>> fetchReciterAudio(String reciterId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reciterAudio?reciter_id=$reciterId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load reciter audio');
  }

  /// Get audio URL for a specific surah by a specific reciter
  String getSurahAudioUrl(String reciterShortName, int surahId) {
    return '$_baseUrl/surahAudio?reciter=$reciterShortName&id=$surahId';
  }

  /// Fetch all azkar (morning, evening, prayer, sleep, etc.)
  Future<Map<String, dynamic>> fetchAzkar() async {
    final response = await http.get(Uri.parse('$_baseUrl/azkar'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load azkar');
  }

  /// Fetch all duas (prophetic, quranic, prophets, quran completion)
  Future<Map<String, dynamic>> fetchDuas() async {
    final response = await http.get(Uri.parse('$_baseUrl/duas'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load duas');
  }

  /// Fetch prayer times (auto-detected by IP location)
  Future<Map<String, dynamic>> fetchPrayerTimes() async {
    final response = await http.get(Uri.parse('$_baseUrl/getPrayerTimes'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load prayer times');
  }
}
