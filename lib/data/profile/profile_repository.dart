import '../../models/artisan_profile.dart';

abstract class ProfileRepository {
  Future<ArtisanProfile?> load(String artisanId);
  Future<void> save({required String artisanId, required ArtisanProfile profile});
  Future<void> clear(String artisanId);
}
