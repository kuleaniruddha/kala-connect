import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/artisan_profile.dart';
import '../../state/app_flow_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/voice_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';
import '../../widgets/magnetic_voice_button.dart';
import '../auth/email_auth_dialog.dart';

class JoinArtistFlow extends StatefulWidget {
  const JoinArtistFlow({super.key});

  @override
  State<JoinArtistFlow> createState() => _JoinArtistFlowState();
}

class _JoinArtistFlowState extends State<JoinArtistFlow> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _storyController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCategory = 'Terracotta & Clay';
  String _selectedLanguage = 'hi';
  int _currentStep = 0;
  String? _listeningField;

  static const _craftCategories = [
    {'name': 'Terracotta & Clay', 'icon': Icons.terrain_rounded, 'color': KalaColors.terracotta},
    {'name': 'Folk Paintings (Madhubani/Pattachitra)', 'icon': Icons.palette_rounded, 'color': KalaColors.indigo},
    {'name': 'Metal & Brass (Dhokra)', 'icon': Icons.hardware_rounded, 'color': KalaColors.turmeric},
    {'name': 'Wooden Craft (Channapatna/Teak)', 'icon': Icons.forest_rounded, 'color': KalaColors.leaf},
    {'name': 'Textiles & Handloom', 'icon': Icons.checkroom_rounded, 'color': Color(0xFFC8395E)},
    {'name': 'Pottery & Ceramics', 'icon': Icons.water_damage_rounded, 'color': Color(0xFF2B7A78)},
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final profile = context.read<AppFlowController>().profile;
    if (profile != null && profile.isArtisan) {
      _nameController.text = profile.name;
      _locationController.text = profile.location;
      _selectedLanguage = profile.languageCode;
      _selectedCategory = profile.craftCategory;
      if (profile.bio != null) _storyController.text = profile.bio!;
    } else if (auth.identity?.displayName != null && auth.identity!.displayName!.isNotEmpty) {
      _nameController.text = auth.identity!.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _storyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _listenForField(String fieldKey) {
    setState(() => _listeningField = fieldKey);
    final voice = context.read<VoiceController>();
    voice.toggleListening();

    void onVoiceUpdate() {
      if (!mounted) return;
      final transcript = voice.lastTranscript;
      if (transcript.isNotEmpty) {
        setState(() {
          if (_listeningField == 'name') {
            _nameController.text = transcript;
          } else if (_listeningField == 'location') {
            _locationController.text = transcript;
          } else if (_listeningField == 'story') {
            _storyController.text = transcript;
          } else if (_listeningField == 'phone') {
            _phoneController.text = transcript.replaceAll(RegExp(r'[^0-9+]'), '');
          }
        });
      }
    }

    voice.addListener(onVoiceUpdate);
  }

  Future<void> _completeArtisanOnboarding() async {
    final auth = context.read<AuthController>();
    if (!auth.isSignedIn) {
      await EmailAuthDialog.show(context);
      if (!mounted) return;
      if (!auth.isSignedIn) return;
    }

    final name = _nameController.text.trim().isEmpty ? 'Traditional Artisan' : _nameController.text.trim();
    final location = _locationController.text.trim().isEmpty ? 'India' : _locationController.text.trim();

    final artisanProfile = ArtisanProfile(
      name: name,
      location: location,
      villageOrCity: location,
      languageCode: _selectedLanguage,
      craftCategory: _selectedCategory,
      bio: _storyController.text.trim(),
      phone: _phoneController.text.trim(),
      isArtisan: true,
    );

    await context.read<AppFlowController>().completeRegistration(artisanProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('बधाई हो, $name! आपका कारीगर खाता तैयार है।'),
          backgroundColor: KalaColors.leaf,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Join as Artisan • कारीगर बनें', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: Column(
            children: [
              // Progress stepper
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: List.generate(4, (index) {
                    final isDone = index <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isDone ? KalaColors.terracotta : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _buildCurrentStep(voice),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A1A1720), blurRadius: 16, offset: Offset(0, -4)),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(60, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          if (_currentStep < 3) {
                            setState(() => _currentStep++);
                          } else {
                            _completeArtisanOnboarding();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: KalaColors.terracotta,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: Icon(_currentStep == 3 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded),
                        label: Text(
                          _currentStep == 3 ? 'Complete & Start Selling' : 'Next Step / आगे बढ़ें',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(VoiceController voice) {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.palette_rounded, color: KalaColors.terracotta, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Select Your Craft\nअपनी कला चुनें',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap your art category or speak to select',
              style: TextStyle(fontSize: 15, color: Color(0xFF6B6572)),
            ),
            const SizedBox(height: 20),
            ..._craftCategories.map((cat) {
              final isSelected = _selectedCategory == cat['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? (cat['color'] as Color).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? (cat['color'] as Color) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x101A1720), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cat['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat['icon'] as IconData, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected ? (cat['color'] as Color) : KalaColors.ink,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: cat['color'] as Color, size: 24),
                    ],
                  ),
                ),
              );
            }),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_pin_circle_rounded, color: KalaColors.terracotta, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Your Identity\nआपका परिचय',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Type or tap the mic button to speak',
              style: TextStyle(fontSize: 15, color: Color(0xFF6B6572)),
            ),
            const SizedBox(height: 24),
            _buildVoiceField(
              label: 'Your Name / आपका नाम',
              hint: 'Enter your full name',
              controller: _nameController,
              fieldKey: 'name',
              icon: Icons.person_rounded,
              voice: voice,
            ),
            const SizedBox(height: 20),
            _buildVoiceField(
              label: 'Village / City & State / गाँव या शहर',
              hint: 'Enter village or city, state',
              controller: _locationController,
              fieldKey: 'location',
              icon: Icons.location_city_rounded,
              voice: voice,
            ),
            const SizedBox(height: 20),
            _buildVoiceField(
              label: 'WhatsApp / Mobile / मोबाइल नंबर',
              hint: 'Enter 10-digit mobile number',
              controller: _phoneController,
              fieldKey: 'phone',
              icon: Icons.phone_rounded,
              voice: voice,
              keyboardType: TextInputType.phone,
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_stories_rounded, color: KalaColors.terracotta, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Your Craft Story\nआपकी कला की कहानी',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.15),
            ),
            const SizedBox(height: 8),
            const Text(
              'How did you learn this craft? Who taught you? Speak freely in your language.',
              style: TextStyle(fontSize: 15, color: Color(0xFF6B6572)),
            ),
            const SizedBox(height: 24),
            Center(
              child: MagneticVoiceButton(
                onPressed: () => _listenForField('story'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                voice.mode == VoiceMode.listening && _listeningField == 'story'
                    ? 'Listening… बोलिए, हम सुन रहे हैं'
                    : 'Tap microphone to speak / माइक दबाकर बोलें',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: KalaColors.terracotta),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _storyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your heritage, materials, techniques, and journey as a creator...',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.85),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ],
        );

      case 3:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_user_rounded, color: KalaColors.leaf, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Preferred Language\nपसंदीदा भाषा',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.15),
            ),
            const SizedBox(height: 8),
            const Text(
              'The AI will guide you and translate buyers’ messages into this language.',
              style: TextStyle(fontSize: 15, color: Color(0xFF6B6572)),
            ),
            const SizedBox(height: 20),
            _buildLanguageSelector(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFF0D4), Color(0xFFFFE3B8)]),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: KalaColors.terracotta),
                      SizedBox(width: 8),
                      Text('AI Studio Ready!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Once completed, you can take a single photo & speak to instantly launch your product on Amazon & ONDC.',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildVoiceField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String fieldKey,
    required IconData icon,
    required VoiceController voice,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isListening = voice.mode == VoiceMode.listening && _listeningField == fieldKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: KalaColors.terracotta),
            suffixIcon: IconButton(
              icon: Icon(
                isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: isListening ? Colors.red : KalaColors.terracotta,
                size: 28,
              ),
              onPressed: () => _listenForField(fieldKey),
            ),
            filled: true,
            fillColor: isListening ? KalaColors.terracotta.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    const languages = [
      {'code': 'hi', 'label': 'हिंदी (Hindi)'},
      {'code': 'en', 'label': 'English'},
      {'code': 'bn', 'label': 'বাংলা (Bengali)'},
      {'code': 'ta', 'label': 'தமிழ் (Tamil)'},
      {'code': 'te', 'label': 'తెలుగు (Telugu)'},
      {'code': 'mr', 'label': 'मराठी (Marathi)'},
      {'code': 'gu', 'label': 'ગુજરાતી (Gujarati)'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: languages.map((lang) {
        final isSelected = _selectedLanguage == lang['code'];
        return ChoiceChip(
          label: Text(lang['label']!, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedLanguage = lang['code']!),
          selectedColor: KalaColors.terracotta,
          labelStyle: TextStyle(color: isSelected ? Colors.white : KalaColors.ink),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        );
      }).toList(),
    );
  }
}
