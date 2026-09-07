import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../models/product_payload.dart';

/// Replace the bodies with a TTS provider or Android/iOS TextToSpeech bridge.
/// The controller only depends on this contract, so the UI stays platform-free.
class AudioInsightService {
  AudioInsightService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();
  final FlutterTts _tts;
  Future<String> synthesiseCommentInsight({
    required List<NativeComment> comments,
    required String languageCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (comments.isEmpty) {
      return languageCode == 'hi' ? 'अभी कोई ग्राहक टिप्पणी नहीं है।' : 'No buyer comments yet.';
    }
    final text = comments.map((comment) => comment.message.toLowerCase()).join(' ');
    final likesColour = text.contains('red') || text.contains('रंग');
    final priceConcern = text.contains('expensive') || text.contains('महंग');
    if (languageCode == 'hi') {
      if (likesColour && priceConcern) return 'लोगों को लाल रंग बहुत पसंद है, लेकिन कुछ लोगों को कीमत थोड़ी अधिक लगती है।';
      return 'ग्राहक आपकी कला की सराहना कर रहे हैं। नई टिप्पणियों को सुनकर देखें।';
    }
    return likesColour && priceConcern
        ? 'People love the red colour, but some feel the price is slightly high.'
        : 'Buyers appreciate your craft. Listen to their latest feedback.';
  }

  Future<void> speak(String message, String languageCode) async {
    await _tts.setLanguage(_localeFor(languageCode));
    await _tts.setSpeechRate(.44);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(message);
  }

  String _localeFor(String code) => switch (code) {
        'bn' => 'bn-IN', 'ta' => 'ta-IN', 'te' => 'te-IN', 'mr' => 'mr-IN',
        'gu' => 'gu-IN', 'kn' => 'kn-IN', 'ml' => 'ml-IN', 'or' => 'or-IN',
        'pa' => 'pa-IN', 'en' => 'en-IN', _ => 'hi-IN',
      };
}
