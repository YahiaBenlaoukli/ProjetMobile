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

    try {
      await docRef.set({
        'total_plays': FieldValue.increment(isNewPlay ? 1 : 0),
        'total_listening_time_seconds': FieldValue.increment(additionalSeconds),
        'surah_plays': {
          surahId.toString(): {
            'count': FieldValue.increment(isNewPlay ? 1 : 0),
            'listening_time_seconds': FieldValue.increment(additionalSeconds),
            'name': surahName,
          }
        },
        'daily_listening': {
          dateKey: FieldValue.increment(additionalSeconds),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating listening stats: $e');
    }
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
