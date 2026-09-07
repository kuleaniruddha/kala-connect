import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/device_capture_service.dart';
import '../../services/image_analysis_service.dart';
import '../../l10n/app_copy.dart';
import '../product/my_products_screen.dart';
import '../../state/app_flow_controller.dart';
import '../../state/product_controller.dart';
import '../../state/voice_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ai_scanner_widget.dart';
import '../../widgets/ambient_living_canvas.dart';
import '../../widgets/magnetic_category_button.dart';
import '../../widgets/magnetic_voice_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _scannerOpen = false;
  bool _capturing = false;

  Future<void> _captureListing() async {
    final heroImage = await context.read<DeviceCaptureService>().captureHeroImage();
    await _analyseImage(heroImage);
  }

  Future<void> _pickListingFromGallery() async {
    final heroImage = await context.read<DeviceCaptureService>().pickHeroImageFromGallery();
    await _analyseImage(heroImage);
  }

  Future<void> _analyseImage(String? heroImage) async {
    if (_capturing) return;
    if (heroImage == null) return;
    setState(() => _capturing = true);
    try {
      final product = await context.read<ImageAnalysisService>().analyse(
        imagePath: heroImage,
        languageCode: context.read<AppFlowController>().profile?.languageCode ?? 'en',
      );
      if (!mounted) return;
      context.read<ProductController>().hydrateFromAiPayload(Map<String, dynamic>.from(product.toJson()));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('We could not analyse this image. Please try another photo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppFlowController>().profile!;
    final copy = AppCopy.forLanguage(profile.languageCode);
    final voice = context.watch<VoiceController>();
    return Scaffold(
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                title: Text('${copy.greeting}, ${profile.name}', style: const TextStyle(fontWeight: FontWeight.w900, color: KalaColors.ink)),
                actions: <Widget>[IconButton(onPressed: voice.readCommentInsights, icon: const Icon(Icons.volume_up_rounded))],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 15, 24, 18),
                  child: Column(children: <Widget>[
                    Text(_scannerOpen ? copy.framePrompt : copy.scanPrompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 29, height: 1.13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 23),
                    if (_scannerOpen)
                      AiScannerWidget(onCapture: _captureListing)
                    else
                      _LaunchScanner(
                        onTap: () => setState(() => _scannerOpen = true),
                        onGalleryTap: _pickListingFromGallery,
                      ),
                    if (_capturing) const Padding(padding: EdgeInsets.only(top: 17), child: CircularProgressIndicator(color: KalaColors.terracotta)),
                    const SizedBox(height: 26),
                    MagneticVoiceButton(onPressed: voice.toggleListening),
                    const SizedBox(height: 11),
                    Text(voice.mode == VoiceMode.listening ? copy.speakPrice : copy.speakHelp, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 9, 24, 36),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1.20,
                  children: <Widget>[
                    MagneticCategoryButton(icon: Icons.inventory_2_rounded, color: KalaColors.terracotta, label: copy.myArt, onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MyProductsScreen()))),
                    MagneticCategoryButton(icon: Icons.local_shipping_rounded, color: KalaColors.indigo, label: copy.orders, onTap: () {}),
                    MagneticCategoryButton(icon: Icons.account_balance_wallet_rounded, color: KalaColors.leaf, label: copy.earnings, onTap: () {}),
                    MagneticCategoryButton(icon: Icons.play_circle_fill_rounded, color: KalaColors.turmeric, label: copy.learn, onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaunchScanner extends StatelessWidget {
  const _LaunchScanner({required this.onTap, required this.onGalleryTap});
  final VoidCallback onTap;
  final VoidCallback onGalleryTap;
  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.forLanguage(context.read<AppFlowController>().profile?.languageCode);
    return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 270,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: const LinearGradient(colors: <Color>[KalaColors.terracotta, Color(0xFFC8395E)]),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x3D9D311F), offset: Offset(0, 17), blurRadius: 27)],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            const Icon(Icons.document_scanner_rounded, size: 76, color: Colors.white),
            const SizedBox(height: 8),
            Text(copy.scanCraft, style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(copy.cameraHint, style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onGalleryTap,
              icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
              label: Text(copy.gallery, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ]),
        ),
      );
  }
}
