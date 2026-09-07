import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/craft_draft.dart';

/// Local persistence boundary. Android/iOS implementations should back this
/// channel with encrypted SharedPreferences/Keychain storage respectively.
class DraftStore {
  DraftStore({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('in.kalaconnect/drafts');

  final MethodChannel _channel;

  /// Persists before network calls, protecting a listing during rural outages.
  Future<void> save(CraftDraft draft) async {
    await _channel.invokeMethod<void>('saveDraft', draft.toJson());
  }

  Future<List<CraftDraft>> loadPending() async {
    final raw = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
          'loadPendingDrafts',
        ) ??
        const <Map<dynamic, dynamic>>[];
    return raw
        .map((item) => CraftDraft.decode(jsonEncode(item)))
        .toList(growable: false);
  }
}
