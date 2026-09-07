import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/artisan_profile.dart';
import '../services/audio_insight_service.dart';
import '../services/voice_assistant_service.dart';
import '../services/voice_command_parser.dart';
import 'app_flow_controller.dart';
import 'product_controller.dart';

enum VoiceMode { idle, listening, speaking }
enum RegistrationField { none, name, location }

/// Owns voice lifecycle, command parsing, profile capture, and buyer insights.
class VoiceController extends ChangeNotifier {
  VoiceController({
    required VoiceAssistantService assistant,
    required AudioInsightService insights,
    required ProductController products,
    required AppFlowController appFlow,
  })  : _assistant = assistant,
        _insights = insights,
        _products = products,
        _appFlow = appFlow {
    _subscription = _assistant.transcripts.listen(_onTranscript);
  }

  final VoiceAssistantService _assistant;
  final AudioInsightService _insights;
  final ProductController _products;
  final AppFlowController _appFlow;
  late final StreamSubscription<VoiceTranscript> _subscription;
  VoiceMode _mode = VoiceMode.idle;
  String _lastTranscript = '';
  String? _pendingName;
  String? _pendingLocation;
  RegistrationField _registrationField = RegistrationField.none;
  String? _lastRegistrationAnswer;

  VoiceMode get mode => _mode;
  String get lastTranscript => _lastTranscript;
  RegistrationField get registrationField => _registrationField;
  String? get lastRegistrationAnswer => _lastRegistrationAnswer;

  Future<void> toggleListening() async {
    if (_mode == VoiceMode.listening) {
      await _assistant.stopListening();
      _mode = VoiceMode.idle;
    } else {
      final languageCode = _appFlow.profile?.languageCode ?? 'en';
      final started = await _assistant.startListening(languageCode: languageCode);
      _mode = started ? VoiceMode.listening : VoiceMode.idle;
    }
    notifyListeners();
  }

  /// Starts one of the two spoken registration answers.  This deliberately
  /// bypasses listing-command parsing so a person's name is never treated as
  /// an edit command.
  Future<void> startRegistrationCapture(RegistrationField field, String languageCode) async {
    _lastRegistrationAnswer = null;
    _registrationField = field;
    final started = await _assistant.startListening(languageCode: languageCode);
    _mode = started ? VoiceMode.listening : VoiceMode.idle;
    notifyListeners();
  }

  /// Handles both a listing command and the two-step voice registration flow.
  void handleFinalTranscript(String transcript) {
    _lastTranscript = transcript;
    _mode = VoiceMode.idle;
    if (_registrationField != RegistrationField.none) {
      final field = _registrationField;
      _registrationField = RegistrationField.none;
      _lastRegistrationAnswer = transcript.trim();
      if (field == RegistrationField.name) {
        _pendingName = _lastRegistrationAnswer;
      } else {
        _pendingLocation = _lastRegistrationAnswer;
      }
      notifyListeners();
      return;
    }
    final command = VoiceCommandParser.parse(transcript);
    switch (command.type) {
      case VoiceCommandType.price:
        _products.changePrice(command.price!);
        unawaited(_speakConfirmation('Price changed to ${command.price!.round()} rupees.'));
        break;
      case VoiceCommandType.moreInfo:
        _products.appendMoreInfo(command.text!);
        unawaited(_speakConfirmation('More information added.'));
        break;
      case VoiceCommandType.deleteImage:
        _products.removeAdditionalImage(command.imageIndex!);
        unawaited(_speakConfirmation('Image removed.'));
        break;
      case VoiceCommandType.changeLanguage:
        unawaited(_appFlow.changeLanguage(command.languageCode!));
        unawaited(_speakConfirmation('Language changed.'));
        break;
      case VoiceCommandType.unknown:
        break;
    }
    _consumeRegistrationAnswer(transcript);
    notifyListeners();
  }

  Future<void> _speakConfirmation(String message) async {
    final languageCode = _appFlow.profile?.languageCode ?? 'en';
    await _insights.speak(message, languageCode);
  }

  void _onTranscript(VoiceTranscript transcript) {
    _lastTranscript = transcript.text;
    if (transcript.isFinal) {
      handleFinalTranscript(transcript.text);
      return;
    }
    notifyListeners();
  }

  void captureRegistrationName(String name) {
    _pendingName = name.trim();
    notifyListeners();
  }

  Future<void> captureRegistrationLocation(String location, String languageCode) async {
    _pendingLocation = location.trim();
    if ((_pendingName ?? '').isNotEmpty && _pendingLocation!.isNotEmpty) {
      await _appFlow.completeRegistration(ArtisanProfile(name: _pendingName!, location: _pendingLocation!, languageCode: languageCode));
    }
    notifyListeners();
  }

  Future<void> readCommentInsights() async {
    final product = _products.product;
    final profile = _appFlow.profile;
    if (product == null || profile == null) return;
    _mode = VoiceMode.speaking;
    notifyListeners();
    final summary = await _insights.synthesiseCommentInsight(comments: product.comments, languageCode: profile.languageCode);
    await _insights.speak(summary, profile.languageCode);
    _lastTranscript = summary;
    _mode = VoiceMode.idle;
    notifyListeners();
  }

  void _consumeRegistrationAnswer(String transcript) {
    // Existing speech engines can prefix registration replies with these keys.
    if (transcript.startsWith('name:')) _pendingName = transcript.substring(5).trim();
    if (transcript.startsWith('location:')) _pendingLocation = transcript.substring(9).trim();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _assistant.dispose();
    super.dispose();
  }
}
