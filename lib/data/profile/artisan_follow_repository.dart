import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class ArtisanFollowRepository {
  ArtisanFollowRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Stream whether the current user follows a given artisan.
  Stream<bool> isFollowing({required String artisanId, required String? userId}) {
    if (userId == null || userId.isEmpty || artisanId.isEmpty) {
      return Stream.value(false);
    }
    return _firestore
        .collection('artisans')
        .doc(artisanId)
        .collection('followers')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists)
        .handleError((_) => false);
  }

  /// Stream the live total follower count for an artisan.
  Stream<int> watchFollowerCount({required String artisanId}) {
    if (artisanId.isEmpty) return Stream.value(0);
    return _firestore
        .collection('artisans')
        .doc(artisanId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((_) => 0);
  }

  /// Stream how many artisans a user is following.
  Stream<int> watchFollowingCount({required String userId}) {
    if (userId.isEmpty) return Stream.value(0);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((_) => 0);
  }

  /// Toggle follow/unfollow state with immediate real-time sync in Firestore.
  Future<bool> toggleFollow({required String artisanId, required String userId}) async {
    if (artisanId.isEmpty || userId.isEmpty) return false;

    final followerDoc = _firestore
        .collection('artisans')
        .doc(artisanId)
        .collection('followers')
        .doc(userId);

    final followingDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .doc(artisanId);

    final snapshot = await followerDoc.get();
    if (snapshot.exists) {
      // Unfollow
      await Future.wait([
        followerDoc.delete(),
        followingDoc.delete(),
      ]);
      return false;
    } else {
      // Follow
      final now = FieldValue.serverTimestamp();
      await Future.wait([
        followerDoc.set({'userId': userId, 'followedAt': now}),
        followingDoc.set({'artisanId': artisanId, 'followedAt': now}),
      ]);
      return true;
    }
  }
}
