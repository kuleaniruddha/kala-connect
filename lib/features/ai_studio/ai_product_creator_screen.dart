import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/ai_studio_service.dart';
import '../../services/audio_insight_service.dart';
import '../../services/device_capture_service.dart';
import '../../services/voice_command_parser.dart';
import '../../state/app_flow_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/product_controller.dart';
import '../../state/voice_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';
import '../../widgets/magnetic_voice_button.dart';
import '../auth/email_auth_dialog.dart';
import '../artisan/join_artist_flow.dart';

class AiProductCreatorScreen extends StatefulWidget {
  const AiProductCreatorScreen({super.key});

  @override
  State<AiProductCreatorScreen> createState() => _AiProductCreatorScreenState();
}

class _AiProductCreatorScreenState extends State<AiProductCreatorScreen> {
  // Photos
  final List<String> _photoPaths = [];
  List<EnhancedStudioPhoto> _enhancedPhotos = [];
  bool _isStudioCleanActive = true;

  // Voice Note & Catalog
  final _voiceNoteController = TextEditingController();
  bool _isGeneratingCatalog = false;
  AutoCatalogResult? _autoCatalog;

  // Pricing
  PriceAssistantResult? _priceResult;
  final int _selectedLaborHours = 6;
  int? _customPrice;
  final _priceTextController = TextEditingController();
  bool _isListeningForPrice = false;

  // Publishing
  bool _isPublishing = false;

  @override
  void dispose() {
    _voiceNoteController.dispose();
    _priceTextController.dispose();
    super.dispose();
  }

  Future<void> _captureHeroPhoto() async {
    final path = await context.read<DeviceCaptureService>().captureHeroImage();
    if (path != null) {
      setState(() => _photoPaths.add(path));
      await _runAiStudioPipeline();
    }
  }

  Future<void> _pickGalleryPhotos() async {
    final path = await context.read<DeviceCaptureService>().pickHeroImageFromGallery();
    if (path != null) {
      setState(() => _photoPaths.add(path));
      await _runAiStudioPipeline();
    }
  }

  Future<void> _pickAdditionalGalleryPhotos() async {
    final paths = await context.read<DeviceCaptureService>().pickAdditionalImages();
    if (paths.isNotEmpty) {
      setState(() => _photoPaths.addAll(paths));
      await _runAiStudioPipeline();
    }
  }

  Future<void> _runAiStudioPipeline() async {
    if (_photoPaths.isEmpty) return;

    final aiService = context.read<AiStudioService>();
    final profile = context.read<AppFlowController>().profile;
    final artisanName = profile?.name ?? 'Master Artisan';
    final artisanLocation = profile?.location ?? 'India';
    final craftCategory = profile?.craftCategory;

    try {
      final enhanced = await aiService.processStudioImages(_photoPaths);
      if (!mounted) return;
      setState(() => _enhancedPhotos = enhanced);

      // If voice note exists or generate default
      final textInput = _voiceNoteController.text.trim().isEmpty
          ? 'Handcrafted traditional artisan craft with natural raw materials'
          : _voiceNoteController.text.trim();

      setState(() => _isGeneratingCatalog = true);
      final catalog = await aiService.generateCatalog(
        voiceTranscriptOrText: textInput,
        artisanLocation: artisanLocation,
        artisanName: artisanName,
        heroImagePath: _photoPaths.isNotEmpty ? _photoPaths.first : null,
        preferredCategory: craftCategory,
      );

      if (!mounted) return;
      setState(() {
        _autoCatalog = catalog;
      });

      final pricing = aiService.estimatePricing(
        category: catalog.category,
        material: catalog.detectedMaterial,
        customLaborHours: _selectedLaborHours,
      );

      setState(() {
        _priceResult = pricing;
        _customPrice = pricing.recommendedPrice;
        _priceTextController.text = '${pricing.recommendedPrice}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingCatalog = false;
        });
      }
    }
  }

  void _onVoiceRecordTap() {
    final voice = context.read<VoiceController>();
    voice.toggleListening();

    void listener() {
      if (!mounted) return;
      final transcript = voice.lastTranscript;
      if (transcript.isNotEmpty) {
        setState(() {
          _voiceNoteController.text = transcript;
        });
        _runAiStudioPipeline();
      }
    }

    voice.addListener(listener);
  }

  void _onVoicePriceTap() async {
    final voice = context.read<VoiceController>();
    if (_isListeningForPrice) {
      await voice.toggleListening();
      setState(() => _isListeningForPrice = false);
      return;
    }

    setState(() => _isListeningForPrice = true);
    if (voice.mode != VoiceMode.listening) {
      await voice.toggleListening();
    }

    void listener() {
      if (!mounted) return;
      final transcript = voice.lastTranscript;
      if (transcript.isNotEmpty) {
        final parsed = VoiceCommandParser.extractPrice(transcript);
        if (parsed != null && parsed > 0) {
          setState(() {
            _customPrice = parsed;
            _priceTextController.text = '$parsed';
            _isListeningForPrice = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Price updated to ₹$parsed via voice!'),
                ],
              ),
              backgroundColor: KalaColors.leaf,
              duration: const Duration(seconds: 2),
            ),
          );
          voice.removeListener(listener);
          return;
        }
      }
      if (voice.mode == VoiceMode.idle && _isListeningForPrice) {
        setState(() => _isListeningForPrice = false);
        voice.removeListener(listener);
      }
    }

    voice.addListener(listener);
  }

  Future<void> _publishCraft() async {
    final auth = context.read<AuthController>();
    if (!auth.isSignedIn) {
      await EmailAuthDialog.show(context);
      if (!mounted) return;
      if (!auth.isSignedIn) return;
    }

    final flow = context.read<AppFlowController>();
    if (flow.profile == null) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const JoinArtistFlow()));
      if (!mounted) return;
      if (flow.profile == null) return;
    }

    if (_photoPaths.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo of your craft.')),
      );
      return;
    }

    setState(() => _isPublishing = true);
    final profile = flow.profile!;
    final aiService = context.read<AiStudioService>();

    try {
      final hero = _enhancedPhotos.isNotEmpty
          ? _enhancedPhotos.first
          : EnhancedStudioPhoto(
              originalPath: _photoPaths.first,
              studioEnhancedPath: _photoPaths.first,
              backgroundRemoved: true,
              lightingEnhanced: true,
              shadowAdded: true,
            );

      final additional = _enhancedPhotos.length > 1
          ? _enhancedPhotos.skip(1).toList()
          : _photoPaths.skip(1).map((p) => EnhancedStudioPhoto(
                originalPath: p,
                studioEnhancedPath: p,
                backgroundRemoved: true,
                lightingEnhanced: true,
                shadowAdded: true,
              )).toList();

      final catalog = _autoCatalog ??
          await aiService.generateCatalog(
            voiceTranscriptOrText: _voiceNoteController.text,
            artisanLocation: profile.location,
            artisanName: profile.name,
            preferredCategory: profile.craftCategory,
          );

      final pricing = _priceResult ??
          aiService.estimatePricing(
            category: catalog.category,
            material: catalog.detectedMaterial,
            customLaborHours: _selectedLaborHours,
          );

      final product = aiService.assembleReadyToSellCatalog(
        id: 'craft-${DateTime.now().millisecondsSinceEpoch}',
        heroPhoto: hero,
        additionalPhotos: additional,
        catalog: catalog,
        pricing: pricing,
        artisanId: auth.identity!.uid,
        artisanName: profile.name,
        artisanLocation: profile.location,
      );

      final finalProduct = _customPrice != null ? product.copyWith(suggestedPrice: _customPrice!) : product;

      if (!mounted) return;
      final productCtrl = context.read<ProductController>();
      productCtrl.hydrateFromAiPayload(Map<String, dynamic>.from(finalProduct.toJson()));
      await productCtrl.publish(auth.identity!.uid);

      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Row(
              children: [
                Icon(Icons.rocket_launch_rounded, color: KalaColors.leaf, size: 30),
                SizedBox(width: 10),
                Text('Published! बधाई हो!', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            content: Text(
              'Your listing "${finalProduct.name}" is now live on the कला-Connect marketplace & ONDC digital catalog!\n\nBuyers across India can now order directly from you.',
              style: const TextStyle(fontSize: 15, height: 1.3),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Reset form
                  setState(() {
                    _photoPaths.clear();
                    _voiceNoteController.clear();
                    _priceTextController.clear();
                    _autoCatalog = null;
                    _priceResult = null;
                    _customPrice = null;
                  });
                },
                style: FilledButton.styleFrom(backgroundColor: KalaColors.terracotta),
                child: const Text('View Marketplace'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('कला AI Studio', style: TextStyle(fontWeight: FontWeight.w900, color: KalaColors.ink)),
        actions: [
          IconButton(
            tooltip: 'How AI Studio Works',
            icon: const Icon(Icons.help_outline_rounded, color: KalaColors.terracotta),
            onPressed: _showAiHelpDialog,
          ),
        ],
      ),
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Manifesto
                _buildHeroManifesto(),
                const SizedBox(height: 24),

                // MODULE 1: ✨ AI PRODUCT STUDIO
                _buildModuleHeader(
                  badgeNumber: '1',
                  title: 'AI PRODUCT STUDIO',
                  subtitle: 'Clean background • Fix lighting • E-commerce ready',
                  color: KalaColors.terracotta,
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: 12),
                _buildAiProductStudioCard(),
                const SizedBox(height: 28),

                // MODULE 2: 🗣️ AI AUTO-CATALOG
                _buildModuleHeader(
                  badgeNumber: '2',
                  title: 'AI AUTO-CATALOG',
                  subtitle: 'Voice → Text • Regional Language → Hindi/English • SEO Description',
                  color: KalaColors.indigo,
                  icon: Icons.record_voice_over_rounded,
                ),
                const SizedBox(height: 12),
                _buildAiAutoCatalogCard(voice),
                const SizedBox(height: 28),

                // MODULE 3: ₹ AI PRICE ASSISTANT
                _buildModuleHeader(
                  badgeNumber: '3',
                  title: 'AI PRICE ASSISTANT',
                  subtitle: 'Product + Material + Market Signals • Competitive Range',
                  color: KalaColors.leaf,
                  icon: Icons.currency_rupee_rounded,
                ),
                const SizedBox(height: 12),
                _buildAiPriceAssistantCard(),
                const SizedBox(height: 32),

                // READY-TO-SELL DIGITAL CATALOG
                _buildReadyToSellSection(),
                const SizedBox(height: 24),

                // 1-Click Publish Button
                FilledButton.icon(
                  onPressed: _isPublishing || _photoPaths.isEmpty ? null : _publishCraft,
                  style: FilledButton.styleFrom(
                    backgroundColor: KalaColors.leaf,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    shadowColor: KalaColors.leaf.withValues(alpha: 0.35),
                  ),
                  icon: _isPublishing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.rocket_launch_rounded, size: 20),
                  label: Text(
                    _isPublishing ? 'Publishing Digital Catalog…' : 'Publish Ready-to-Sell Catalog',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Instant live listing on कला-Connect & ONDC marketplace',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B6572), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroManifesto() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2238), Color(0xFF4A2545)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KalaColors.turmeric,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'ONE PHOTO + ONE VOICE NOTE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: KalaColors.ink),
                ),
              ),
              const Spacer(),
              const Icon(Icons.flare_rounded, color: KalaColors.turmeric, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'From “I make it” to “I can sell it.”',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Row(
                children: [
                  _ManifestoItem(icon: Icons.camera_alt_rounded, label: 'Studio Photos'),
                  SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.white38)),
                  SizedBox(width: 8),
                  _ManifestoItem(icon: Icons.auto_awesome_rounded, label: 'Auto Listings'),
                  SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.white38)),
                  SizedBox(width: 8),
                  _ManifestoItem(icon: Icons.currency_rupee_rounded, label: 'Fair Pricing'),
                  SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.white38)),
                  SizedBox(width: 8),
                  _ManifestoItem(icon: Icons.public_rounded, label: 'Direct Buyers'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleHeader({
    required String badgeNumber,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.3),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('AI CORE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B6572), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // MODULE 1: AI PRODUCT STUDIO
  Widget _buildAiProductStudioCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: KalaColors.terracotta.withValues(alpha: 0.2), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x101A1720), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_photoPaths.isEmpty) ...[
            // Empty photo state: Capture or Pick
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _captureHeroPhoto,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [KalaColors.terracotta.withValues(alpha: 0.12), KalaColors.turmeric.withValues(alpha: 0.15)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: KalaColors.terracotta.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 40, color: KalaColors.terracotta),
                          SizedBox(height: 8),
                          Text('Click Photo', style: TextStyle(fontWeight: FontWeight.w900, color: KalaColors.ink)),
                          Text('तस्वीर खींचे', style: TextStyle(fontSize: 11, color: Color(0xFF6B6572))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickGalleryPhotos,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black12, width: 1.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_rounded, size: 40, color: KalaColors.indigo),
                          SizedBox(height: 8),
                          Text('Upload Gallery', style: TextStyle(fontWeight: FontWeight.w900, color: KalaColors.ink)),
                          Text('गैलरी से चुनें', style: TextStyle(fontSize: 11, color: Color(0xFF6B6572))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Has photos: show Clean background studio toggle & preview
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: KalaColors.terracotta, size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Studio View',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Raw', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: true, label: Text('AI Clean', style: TextStyle(fontSize: 11))),
                  ],
                  selected: {_isStudioCleanActive},
                  onSelectionChanged: (set) => setState(() => _isStudioCleanActive = set.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    selectedBackgroundColor: KalaColors.terracotta,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Hero Photo Box with Studio treatment
            Center(
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isStudioCleanActive ? const Color(0xFFFBF9F5) : Colors.black12,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _isStudioCleanActive
                      ? const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 22, offset: Offset(0, 10)),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      File((_isStudioCleanActive && _enhancedPhotos.isNotEmpty)
                          ? _enhancedPhotos.first.studioEnhancedPath
                          : _photoPaths.first),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_rounded, size: 60)),
                    ),
                    if (_isStudioCleanActive)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: KalaColors.turmeric, size: 14),
                              SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Clean Background • Studio Lighting Active',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Additional photos rail (Amazon-style multi-photo)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Multi-Angle Photos:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickAdditionalGalleryPhotos,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                  label: const Text('Add More', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photoPaths.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == _photoPaths.length) {
                    return GestureDetector(
                      onTap: _pickAdditionalGalleryPhotos,
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black26, style: BorderStyle.solid),
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, color: KalaColors.terracotta),
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_photoPaths[index]),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // MODULE 2: AI AUTO-CATALOG
  Widget _buildAiAutoCatalogCard(VoiceController voice) {
    final isListening = voice.mode == VoiceMode.listening;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: KalaColors.indigo.withValues(alpha: 0.2), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x101A1720), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Speak Product Description', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(
                      isListening ? 'Listening… बोलिए, AI सुन रहा है' : 'Tap mic to speak in Hindi or regional language',
                      style: TextStyle(
                        fontSize: 12,
                        color: isListening ? KalaColors.terracotta : const Color(0xFF6B6572),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              MagneticVoiceButton(onPressed: _onVoiceRecordTap),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _voiceNoteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. "मिट्टी का पारंपरिक बांकुरा घोड़ा, हाथ से नक्काशी किया हुआ..." or type description',
              filled: true,
              fillColor: isListening ? KalaColors.indigo.withValues(alpha: 0.08) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.auto_awesome_rounded, color: KalaColors.indigo),
                tooltip: 'Regenerate Catalog',
                onPressed: _runAiStudioPipeline,
              ),
            ),
          ),
          if (_isGeneratingCatalog) ...[
            const SizedBox(height: 14),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: KalaColors.indigo)),
                  SizedBox(width: 10),
                  Text('AI generating multilingual catalog…', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            ),
          ] else if (_autoCatalog != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KalaColors.indigo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KalaColors.indigo.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: KalaColors.leaf, size: 16),
                      const SizedBox(width: 5),
                      const Expanded(
                        child: Text(
                          'SEO Title (Amazon Standard)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Chip(
                        label: Text(_autoCatalog!.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _autoCatalog!.seoTitle,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: KalaColors.ink),
                  ),
                  const Divider(height: 20),
                  const Text('Dual-Language Description:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    _autoCatalog!.englishDescription,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _autoCatalog!.hindiDescription,
                    style: const TextStyle(fontSize: 13, height: 1.3, color: Color(0xFF4A3525)),
                  ),
                  if (_autoCatalog!.spokenVoiceGuide.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        context.read<AudioInsightService>().speak(_autoCatalog!.spokenVoiceGuide, 'hi');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: KalaColors.terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KalaColors.terracotta.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.volume_up_rounded, color: KalaColors.terracotta, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'बोलकर सुनें (Tap to hear AI description in Hindi)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: KalaColors.terracotta,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _autoCatalog!.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('#$t', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: KalaColors.indigo)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // MODULE 3: AI PRICE ASSISTANT
  Widget _buildAiPriceAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: KalaColors.leaf.withValues(alpha: 0.2), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x101A1720), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_priceResult == null) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Add a photo or voice note to calculate fair dynamic price.'),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0xFFFFF0A6), KalaColors.turmeric]),
                  ),
                  child: const Center(
                    child: Icon(Icons.currency_rupee_rounded, size: 30, color: KalaColors.ink),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recommended Selling Price', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            '₹${_customPrice ?? _priceResult!.recommendedPrice}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: KalaColors.ink),
                          ),
                          Text(
                            'MRP ₹${_priceResult!.mrp}',
                            style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black45, fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: KalaColors.leaf.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '${_priceResult!.discountPercent}% OFF',
                              style: const TextStyle(color: KalaColors.leaf, fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Market Range: ₹${_priceResult!.minSustainablePrice} – ₹${_priceResult!.maxPremiumPrice}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: KalaColors.leaf),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Transparent cost breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KalaColors.leaf.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Raw Material Cost:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('₹${_priceResult!.materialCost}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Fair Artisan Labor ($_selectedLaborHours hrs):',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('₹${_priceResult!.artisanFairWage}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KalaColors.terracotta.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.trending_up_rounded, size: 15, color: KalaColors.terracotta),
                            SizedBox(width: 6),
                            Text(
                              'Market Demand Signal',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KalaColors.terracotta),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _priceResult!.marketDemandIndex,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KalaColors.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Customize Selling Price (Voice & Text):',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: KalaColors.ink),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isListeningForPrice ? KalaColors.terracotta : KalaColors.leaf.withValues(alpha: 0.35),
                  width: _isListeningForPrice ? 2 : 1.5,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x0E000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: KalaColors.leaf.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('₹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KalaColors.leaf)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Type price or speak',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B6572)),
                        ),
                        TextField(
                          controller: _priceTextController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KalaColors.ink),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 2),
                            border: InputBorder.none,
                            hintText: 'Enter price',
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              setState(() => _customPrice = parsed);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onVoicePriceTap,
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isListeningForPrice ? KalaColors.terracotta : KalaColors.terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isListeningForPrice ? KalaColors.terracotta : KalaColors.terracotta.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isListeningForPrice ? Icons.mic_rounded : Icons.mic_none_rounded,
                              size: 18,
                              color: _isListeningForPrice ? Colors.white : KalaColors.terracotta,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isListeningForPrice ? 'Listening…' : 'Voice',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _isListeningForPrice ? Colors.white : KalaColors.terracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isListeningForPrice) ...[
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: KalaColors.terracotta),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Speak now: e.g. "850", "900 rupees", "कीमत 800"',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: KalaColors.terracotta),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Fine-tune with Slider:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF6B6572)),
                  ),
                ),
                Text(
                  '₹${_customPrice ?? _priceResult!.recommendedPrice}',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: KalaColors.leaf, fontSize: 14),
                ),
              ],
            ),
            Slider(
              value: (_customPrice ?? _priceResult!.recommendedPrice)
                  .toDouble()
                  .clamp(
                    _priceResult!.minSustainablePrice.toDouble(),
                    (_priceResult!.maxPremiumPrice < (_customPrice ?? _priceResult!.recommendedPrice)
                        ? (_customPrice ?? _priceResult!.recommendedPrice).toDouble()
                        : _priceResult!.maxPremiumPrice.toDouble()),
                  ),
              min: _priceResult!.minSustainablePrice.toDouble(),
              max: (_priceResult!.maxPremiumPrice < (_customPrice ?? _priceResult!.recommendedPrice)
                  ? (_customPrice ?? _priceResult!.recommendedPrice).toDouble()
                  : _priceResult!.maxPremiumPrice.toDouble()),
              divisions: 20,
              activeColor: KalaColors.leaf,
              onChanged: (val) {
                final rounded = val.round();
                setState(() {
                  _customPrice = rounded;
                  _priceTextController.text = '$rounded';
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: ₹${_priceResult!.minSustainablePrice}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black45),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _customPrice = _priceResult!.recommendedPrice;
                      _priceTextController.text = '${_priceResult!.recommendedPrice}';
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Reset to AI (₹${_priceResult!.recommendedPrice})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: KalaColors.indigo),
                    ),
                  ),
                ),
                Text(
                  'Max: ₹${_priceResult!.maxPremiumPrice}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black45),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // READY-TO-SELL PREVIEW
  Widget _buildReadyToSellSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x181A1720), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: KalaColors.turmeric.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.storefront_rounded, color: KalaColors.ink, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('READY-TO-SELL DIGITAL CATALOG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    Text('How your craft appears to buyers on Amazon & कला-Connect', style: TextStyle(fontSize: 11, color: Color(0xFF6B6572))),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (_photoPaths.isNotEmpty && _autoCatalog != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_photoPaths.first),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _autoCatalog!.seoTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${context.read<AppFlowController>().profile?.name ?? "Master Artisan"} • Verified Craft',
                        style: const TextStyle(fontSize: 11, color: KalaColors.leaf, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text('₹${_customPrice ?? _priceResult?.recommendedPrice ?? 750}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: KalaColors.ink)),
                          if (_priceResult != null)
                            Text('₹${_priceResult!.mrp}',
                                style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12, color: Colors.black45)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Complete the 3 AI modules above to preview your digital catalog.', textAlign: TextAlign.center),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAiHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('कला AI Studio Process', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. ✨ AI Product Studio: Takes regular phone camera photos and creates high-converting e-commerce white/neutral studio backdrops with enhanced lighting.', style: TextStyle(fontSize: 13, height: 1.3)),
            SizedBox(height: 10),
            Text('2. 🗣️ AI Auto-Catalog: Converts your spoken Hindi/regional voice note into e-commerce SEO titles, dual-language descriptions, and bullet points.', style: TextStyle(fontSize: 13, height: 1.3)),
            SizedBox(height: 10),
            Text('3. ₹ AI Price Assistant: Analyzes raw materials, craftsmanship hours, and live market benchmarks to recommend a competitive price that guarantees a living artisan wage.', style: TextStyle(fontSize: 13, height: 1.3)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: KalaColors.terracotta),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _ManifestoItem extends StatelessWidget {
  const _ManifestoItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: KalaColors.turmeric),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
