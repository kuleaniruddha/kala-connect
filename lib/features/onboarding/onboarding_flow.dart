import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/voice_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';
import '../../widgets/magnetic_voice_button.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  String? _language;
  int _step = 0;

  void _selectLanguage(String code) => setState(() {
        _language = code;
        _step = 1;
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AmbientLivingCanvas(
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              child: _step == 0
                  ? LanguageSelectionScreen(onLanguageSelected: _selectLanguage)
                  : VoiceRegistrationScreen(languageCode: _language!),
            ),
          ),
        ),
      );
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({required this.onLanguageSelected, super.key});
  final ValueChanged<String> onLanguageSelected;

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  static const _languages = <_LanguageOption>[
    _LanguageOption('English', 'English', 'en', KalaColors.indigo, Icons.language_rounded),
    _LanguageOption('हिंदी', 'Hindi', 'hi', KalaColors.terracotta, Icons.waving_hand_rounded),
    _LanguageOption('বাংলা', 'Bangla', 'bn', KalaColors.indigo, Icons.water_drop_rounded),
    _LanguageOption('मराठी', 'Marathi', 'mr', KalaColors.turmeric, Icons.auto_awesome_rounded),
    _LanguageOption('தமிழ்', 'Tamil', 'ta', KalaColors.leaf, Icons.temple_hindu_rounded),
    _LanguageOption('తెలుగు', 'Telugu', 'te', Color(0xFF9B4D92), Icons.brightness_5_rounded),
    _LanguageOption('ગુજરાતી', 'Gujarati', 'gu', Color(0xFF3478B8), Icons.diamond_rounded),
  ];

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          const Text('Your voice,\nyour language', style: TextStyle(fontSize: 35, height: 1.05, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          const Text('Choose the language you speak', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const Spacer(),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _languages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 1.04),
            itemBuilder: (context, index) {
              final option = _languages[index];
              final begin = (index * .10).clamp(0.0, .55).toDouble();
              return FadeTransition(
                opacity: CurvedAnimation(parent: _controller, curve: Interval(begin, begin + .45, curve: Curves.easeOut)),
                child: _LanguageTile(option: option, onTap: () => widget.onLanguageSelected(option.code)),
              );
            },
          ),
          const Spacer(),
          const Center(child: Icon(Icons.graphic_eq_rounded, size: 42, color: KalaColors.terracotta)),
        ]),
      );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.option, required this.onTap});
  final _LanguageOption option;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[option.color.withValues(alpha: .90), option.color.withValues(alpha: .62)]),
            boxShadow: <BoxShadow>[BoxShadow(color: option.color.withValues(alpha: .35), offset: const Offset(0, 12), blurRadius: 22)],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Icon(option.icon, color: Colors.white, size: 44),
            const SizedBox(height: 10),
            Text(option.nativeName, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
            Text(option.englishName, style: const TextStyle(color: Color(0xDAFFFFFF), fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class VoiceRegistrationScreen extends StatefulWidget {
  const VoiceRegistrationScreen({required this.languageCode, super.key});
  final String languageCode;
  @override
  State<VoiceRegistrationScreen> createState() => _VoiceRegistrationScreenState();
}

class _VoiceRegistrationScreenState extends State<VoiceRegistrationScreen> {
  int _step = 0;
  String? _handledAnswer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<VoiceController>().removeListener(_handleVoiceUpdate);
    context.read<VoiceController>().addListener(_handleVoiceUpdate);
  }

  @override
  void dispose() {
    context.read<VoiceController>().removeListener(_handleVoiceUpdate);
    super.dispose();
  }

  void _handleVoiceUpdate() {
    if (!mounted) return;
    final voice = context.read<VoiceController>();
    final answer = voice.lastRegistrationAnswer;
    if (answer == null || answer.isEmpty || answer == _handledAnswer) return;
    _handledAnswer = answer;
    if (_step == 0) {
      voice.captureRegistrationName(answer);
      setState(() => _step = 1);
    } else {
      voice.captureRegistrationLocation(answer, widget.languageCode);
    }
  }

  void _captureAnswer(BuildContext context) {
    final voice = context.read<VoiceController>();
    voice.startRegistrationCapture(
      _step == 0 ? RegistrationField.name : RegistrationField.location,
      widget.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceController>();
    final askingName = _step == 0;
    return Padding(
      key: ValueKey<int>(_step),
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Icon(askingName ? Icons.face_rounded : Icons.location_on_rounded, size: 104, color: KalaColors.terracotta),
        const SizedBox(height: 30),
        Text(askingName ? 'What is your name?' : 'Where are you from?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, height: 1.12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Text(askingName ? 'Tap the microphone and say your name' : 'Tap the microphone and say your village or city', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
        const SizedBox(height: 44),
        MagneticVoiceButton(onPressed: () => _captureAnswer(context)),
        const SizedBox(height: 22),
        Text(voice.mode == VoiceMode.listening ? 'Listening…' : 'Speak now', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ]),
    );
  }
}

class _LanguageOption {
  const _LanguageOption(this.nativeName, this.englishName, this.code, this.color, this.icon);
  final String nativeName;
  final String englishName;
  final String code;
  final Color color;
  final IconData icon;
}
