import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/artisan_profile.dart';
import 'profile_repository.dart';

/// Offline cache used when Firebase is unreachable and in the unconfigured demo.
class LocalProfileRepository implements ProfileRepository {
  static const _prefix = 'artisan_profile_';

  @override
  Future<void> clear(String artisanId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_prefix$artisanId');
  }

  @override
  Future<ArtisanProfile?> load(String artisanId) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('$_prefix$artisanId');
    if (encoded == null) return null;
    return ArtisanProfile.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  }

  @override
  Future<void> save({required String artisanId, required ArtisanProfile profile}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('$_prefix$artisanId', jsonEncode(profile.toJson()));
  }
}
