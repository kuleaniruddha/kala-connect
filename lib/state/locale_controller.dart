import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class LocaleController extends ChangeNotifier {
  LocaleController() {
    _loadSavedLanguage();
  }

  static const _prefKey = 'app_selected_language_code';
  String _languageCode = 'hi'; // Default to Hindi for authentic Indian artisan context

  String get languageCode => _languageCode;
  AppLocalizations get l10n => AppLocalizations(_languageCode);

  String tr(String key) => l10n.translate(key);

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.isNotEmpty && saved != _languageCode) {
        _languageCode = saved;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }
}
