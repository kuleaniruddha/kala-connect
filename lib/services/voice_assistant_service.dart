import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceTranscript {
  const VoiceTranscript({required this.text, required this.isFinal});
  final String text;
  final bool isFinal;
}

/// Native speech recognition boundary. Android system speech services choose
/// language packs; the selected app language is sent as a BCP-47 locale id.
class VoiceAssistantService {
  VoiceAssistantService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  final StreamController<VoiceTranscript> _transcripts = StreamController<VoiceTranscript>.broadcast();
  bool _initialized = false;

  Stream<VoiceTranscript> get transcripts => _transcripts.stream;

  Future<bool> startListening({String languageCode = 'hi'}) async {
    if (!_initialized) {
      _initialized = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    }
    if (!_initialized) return false;
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: _localeFor(languageCode),
        partialResults: true,
        listenMode: ListenMode.confirmation,
      ),
      onResult: _onResult,
    );
    return true;
  }

  Future<void> stopListening() => _speech.stop();

  /// Allows an existing speech engine or widget test to submit a final phrase.
  void submitTranscript(String transcript) => _transcripts.add(VoiceTranscript(text: transcript.trim(), isFinal: true));

  void _onResult(SpeechRecognitionResult result) {
    _transcripts.add(VoiceTranscript(text: result.recognizedWords.trim(), isFinal: result.finalResult));
  }

  String _localeFor(String code) => switch (code) {
        'bn' => 'bn-IN',
        'ta' => 'ta-IN',
        'te' => 'te-IN',
        'mr' => 'mr-IN',
        'gu' => 'gu-IN',
        'kn' => 'kn-IN',
        'ml' => 'ml-IN',
        'or' => 'or-IN',
        'pa' => 'pa-IN',
        'en' => 'en-IN',
        _ => 'hi-IN',
      };

  Future<void> dispose() async {
    await _speech.stop();
    await _transcripts.close();
  }
}
