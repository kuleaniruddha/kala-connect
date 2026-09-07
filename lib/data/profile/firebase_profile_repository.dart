import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/artisan_profile.dart';
import 'profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profile(String artisanId) => _firestore.collection('artisans').doc(artisanId);

  @override
  Future<ArtisanProfile?> load(String artisanId) async {
    final snapshot = await _profile(artisanId).get(const GetOptions(source: Source.serverAndCache));
    final data = snapshot.data();
    if (data == null || !data.containsKey('name') || data['isArtisan'] != true) return null;
    return ArtisanProfile.fromJson(data);
  }

  @override
  Future<void> save({required String artisanId, required ArtisanProfile profile}) => _profile(artisanId).set(<String, Object?>{
        ...profile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  @override
  Future<void> clear(String artisanId) async {}
}
