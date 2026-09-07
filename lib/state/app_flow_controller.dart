import 'package:flutter/foundation.dart';

import '../data/profile/profile_repository.dart';
import '../models/artisan_profile.dart';

enum EntryStage { landing, authentication }

class AppFlowController extends ChangeNotifier {
  AppFlowController(this._profiles);

  final ProfileRepository _profiles;
  ArtisanProfile? _profile;
  EntryStage _entryStage = EntryStage.landing;
  String? _artisanId;
  bool _isLoadingProfile = false;

  ArtisanProfile? get profile => _profile;
  bool get isOnboarded => _profile != null;
  EntryStage get entryStage => _entryStage;
  bool get isLoadingProfile => _isLoadingProfile;
  bool isBoundTo(String artisanId) => _artisanId == artisanId;

  /// Called by the auth gate once per signed-in account, including app restarts.
  Future<void> bindArtisan(String artisanId) async {
    if (_artisanId == artisanId) return;
    _artisanId = artisanId;
    _isLoadingProfile = true;
    notifyListeners();
    try {
      _profile = await _profiles.load(artisanId);
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  void unbindArtisan() {
    _artisanId = null;
    _profile = null;
    _isLoadingProfile = false;
  }

  void openAuthentication() {
    _entryStage = EntryStage.authentication;
    notifyListeners();
  }

  void returnToLanding() {
    _entryStage = EntryStage.landing;
    notifyListeners();
  }

  Future<void> completeRegistration(ArtisanProfile profile) async {
    _profile = profile;
    final artisanId = _artisanId;
    if (artisanId != null) await _profiles.save(artisanId: artisanId, profile: profile);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    final profile = _profile;
    if (profile == null || profile.languageCode == languageCode) return;
    await completeRegistration(ArtisanProfile(name: profile.name, location: profile.location, languageCode: languageCode));
  }
}
