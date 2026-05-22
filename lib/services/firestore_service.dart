import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get userId => _auth.currentUser?.uid;

  /// Stream of user's favorite track IDs.
  Stream<List<int>> getFavorites() {
    if (userId == null) return Stream.value([]);
    
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => int.parse(doc.id)).toList();
    });
  }

  /// Add a track to favorites.
  Future<void> addFavorite(int trackId) async {
    if (userId == null) return;
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(trackId.toString())
        .set({'added_at': FieldValue.serverTimestamp()});
  }

  /// Remove a track from favorites.
  Future<void> removeFavorite(int trackId) async {
    if (userId == null) return;
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(trackId.toString())
        .delete();
  }

  /// Increment play count for statistics.
  Future<void> recordPlay() async {
    if (userId == null) return;
    final docRef = _db.collection('users').doc(userId).collection('stats').doc('usage');
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        transaction.set(docRef, {'total_plays': 1});
      } else {
        final current = snapshot.data()?['total_plays'] ?? 0;
        transaction.update(docRef, {'total_plays': current + 1});
      }
    });
  }

  /// Get total play count.
  Stream<int> getTotalPlays() {
    if (userId == null) return Stream.value(0);
    return _db
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('usage')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      return snapshot.data()?['total_plays'] ?? 0;
    });
  }

  /// Update listening stats (total plays, total time, per-surah, and daily analytics).
  Future<void> updateListeningStats({
    required int surahId,
    required String surahName,
    required int additionalSeconds,
    bool isNewPlay = false,
  }) async {
    if (userId == null) return;
    final docRef = _db.collection('users').doc(userId).collection('stats').doc('usage');
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {
          'total_plays': isNewPlay ? 1 : 0,
          'total_listening_time_seconds': additionalSeconds,
          'surah_plays': {
            surahId.toString(): {
              'count': isNewPlay ? 1 : 0,
              'name': surahName,
              'listening_time_seconds': additionalSeconds,
            }
          },
          'daily_listening': {
            dateKey: additionalSeconds,
          },
        });
      } else {
        final data = snapshot.data() ?? {};
        final totalPlays = (data['total_plays'] ?? 0) + (isNewPlay ? 1 : 0);
        final totalTime = (data['total_listening_time_seconds'] ?? 0) + additionalSeconds;

        final Map<String, dynamic> surahPlays = Map<String, dynamic>.from(data['surah_plays'] ?? {});
        final surahKey = surahId.toString();

        if (surahPlays.containsKey(surahKey)) {
          final surahData = Map<String, dynamic>.from(surahPlays[surahKey]);
          final currentCount = surahData['count'] ?? 0;
          final currentTime = surahData['listening_time_seconds'] ?? 0;

          surahData['count'] = currentCount + (isNewPlay ? 1 : 0);
          surahData['listening_time_seconds'] = currentTime + additionalSeconds;
          surahPlays[surahKey] = surahData;
        } else {
          surahPlays[surahKey] = {
            'count': isNewPlay ? 1 : 0,
            'name': surahName,
            'listening_time_seconds': additionalSeconds,
          };
        }

        // Update daily listening
        final Map<String, dynamic> dailyListening = Map<String, dynamic>.from(data['daily_listening'] ?? {});
        dailyListening[dateKey] = (dailyListening[dateKey] ?? 0) + additionalSeconds;

        transaction.update(docRef, {
          'total_plays': totalPlays,
          'total_listening_time_seconds': totalTime,
          'surah_plays': surahPlays,
          'daily_listening': dailyListening,
        });
      }
    });
  }

  /// Get real-time stream of all user stats.
  Stream<Map<String, dynamic>> getStatsStream() {
    if (userId == null) return Stream.value({});
    return _db
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('usage')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return {};
      return snapshot.data() ?? {};
    });
  }
}
