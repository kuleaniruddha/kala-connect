import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product_payload.dart';
import '../../services/device_capture_service.dart';
import '../../state/app_flow_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/product_controller.dart';
import '../../state/voice_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';
import '../../widgets/magnetic_voice_button.dart';

/// Strict reusable listing layout. It only appears when ProductController has
/// received a structured edge/AI payload; it never manufactures product data.
class ProductDetailsView extends StatefulWidget {
  const ProductDetailsView({super.key});

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _stagger({required int position, required Widget child}) {
    final start = .06 + position * .12;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entrance, curve: Interval(start, (start + .42).clamp(0, 1).toDouble(), curve: Curves.easeOutCubic)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .18), end: Offset.zero).animate(
          CurvedAnimation(parent: _entrance, curve: Interval(start, (start + .48).clamp(0, 1).toDouble(), curve: Curves.easeOutBack)),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductController>().product;
    final hindi = context.watch<AppFlowController>().profile?.languageCode == 'hi';
    if (product == null) return const SizedBox.shrink();
    return Scaffold(
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => context.read<ProductController>().clear(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: Text(hindi ? 'मेरी नई कला' : 'My new craft', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    _stagger(position: 0, child: _HeroImage(path: product.heroImagePath)),
                    const SizedBox(height: 20),
                    _stagger(position: 1, child: _CatalogIdentity(product: product)),
                    const SizedBox(height: 16),
                    _stagger(position: 2, child: _Description(description: product.description, tags: product.tags, hindi: hindi)),
                    const SizedBox(height: 16),
                    _stagger(position: 2, child: _PriceOrb(product: product, hindi: hindi)),
                    const SizedBox(height: 16),
                    _stagger(position: 3, child: _MoreInfo(product: product, hindi: hindi)),
                    const SizedBox(height: 16),
                    _stagger(position: 4, child: _Comments(product: product, hindi: hindi)),
                    const SizedBox(height: 26),
                    _stagger(position: 5, child: _VoiceDock()),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final network = path.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: AspectRatio(
        aspectRatio: 1.05,
        child: network
            ? Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _HeroFallback())
            : Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _HeroFallback()),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: <Color>[KalaColors.terracotta, KalaColors.indigo])),
        child: Center(child: Icon(Icons.auto_awesome_rounded, size: 100, color: Color(0x77FFFFFF))),
      );
}

class _CatalogIdentity extends StatelessWidget {
  const _CatalogIdentity({required this.product});
  final ProductPayload product;

  @override
  Widget build(BuildContext context) => _InkPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(product.category, style: const TextStyle(color: KalaColors.leaf, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _Description extends StatelessWidget {
  const _Description({required this.description, required this.tags, required this.hindi});
  final String description;
  final List<String> tags;
  final bool hindi;

  @override
  Widget build(BuildContext context) => _InkPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          _PanelLabel(icon: Icons.auto_awesome_rounded, label: hindi ? 'AI ने लिखा' : 'AI description'),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 18, height: 1.35, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Wrap(spacing: 7, runSpacing: 7, children: tags.map((tag) => Chip(label: Text(tag), side: BorderSide.none, backgroundColor: KalaColors.turmeric.withValues(alpha: .28))).toList()),
        ]),
      );
}

class _PriceOrb extends StatelessWidget {
  const _PriceOrb({required this.product, required this.hindi});
  final ProductPayload product;
  final bool hindi;

  void _showPriceDialog(BuildContext context) {
    final controller = TextEditingController(text: '${product.suggestedPrice}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(hindi ? 'कीमत बदलें' : 'Edit Price', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hindi ? 'नया दाम दर्ज करें (₹):' : 'Enter new price (₹):',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B6572)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(hindi ? 'रद्द करें' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                context.read<ProductController>().changePrice(val);
              }
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: KalaColors.terracotta),
            child: Text(hindi ? 'सुरक्षित करें' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _InkPanel(
        child: Row(children: <Widget>[
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: <Color>[Color(0xFFFFF0A6), KalaColors.turmeric])),
            child: const Icon(Icons.currency_rupee_rounded, size: 38),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: InkWell(
              onTap: () => _showPriceDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Row(
                  children: [
                    Text(hindi ? 'सुझाई गई कीमत' : 'Suggested price', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_rounded, size: 14, color: KalaColors.indigo),
                  ],
                ),
                Text('₹${product.suggestedPrice}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 34)),
                Text('Market range: ₹${product.priceLow} – ₹${product.priceHigh}', style: const TextStyle(fontWeight: FontWeight.w700, color: KalaColors.leaf)),
              ]),
            ),
          ),
          IconButton(
            onPressed: () => _showPriceDialog(context),
            icon: const Icon(Icons.edit_note_rounded, color: KalaColors.indigo, size: 28),
            tooltip: hindi ? 'लिखकर कीमत बदलें' : 'Type to change price',
          ),
          IconButton(
            onPressed: () => context.read<VoiceController>().toggleListening(),
            icon: const Icon(Icons.mic_rounded, color: KalaColors.terracotta, size: 28),
            tooltip: hindi ? 'कहकर कीमत बदलें' : 'Say a price to change it',
          ),
        ]),
      );
}

class _MoreInfo extends StatelessWidget {
  const _MoreInfo({required this.product, required this.hindi});
  final ProductPayload product;
  final bool hindi;

  @override
  Widget build(BuildContext context) => _InkPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: _PanelLabel(icon: Icons.info_outline_rounded, label: hindi ? 'और जानकारी' : 'More information')),
            IconButton(
              onPressed: () async {
                final images = await context.read<DeviceCaptureService>().pickAdditionalImages();
                if (!context.mounted) return;
                context.read<ProductController>().addAdditionalImages(images);
              },
              icon: const Icon(Icons.add_photo_alternate_rounded, color: KalaColors.terracotta),
              tooltip: hindi ? 'और तस्वीरें जोड़ें' : 'Add more images',
            ),
          ]),
          const SizedBox(height: 9),
          Text(product.moreInfo, style: const TextStyle(height: 1.35)),
          if (product.additionalImages.isNotEmpty) ...<Widget>[
            const SizedBox(height: 15),
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: product.additionalImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _GalleryImage(path: product.additionalImages[index]),
              ),
            ),
          ],
        ]),
      );
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.path});
  final String path;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: path.startsWith('http')
            ? Image.network(path, width: 108, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _GalleryFallback())
            : Image.file(File(path), width: 108, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _GalleryFallback()),
      );
}

class _GalleryFallback extends StatelessWidget {
  const _GalleryFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(color: Color(0x22E85D3F), child: SizedBox(width: 108, child: Icon(Icons.image_not_supported_rounded)));
}

class _Comments extends StatelessWidget {
  const _Comments({required this.product, required this.hindi});
  final ProductPayload product;
  final bool hindi;

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceController>();
    final language = context.watch<AppFlowController>().profile?.languageCode ?? 'en';
    return _InkPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[
          Expanded(child: _PanelLabel(icon: Icons.forum_rounded, label: hindi ? 'ग्राहकों की बातें' : 'Buyer comments')),
          IconButton(onPressed: voice.readCommentInsights, icon: const Icon(Icons.volume_up_rounded, color: KalaColors.indigo)),
        ]),
        const SizedBox(height: 8),
        ...product.comments.map((comment) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('${comment.author}: ${comment.message}', style: const TextStyle(fontSize: 15, height: 1.25)),
            )),
        const SizedBox(height: 13),
        _VoiceCommentAction(languageCode: language, hindi: hindi),
      ]),
    );
  }
}

class _VoiceCommentAction extends StatelessWidget {
  const _VoiceCommentAction({required this.languageCode, required this.hindi});
  final String languageCode;
  final bool hindi;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => context.read<ProductController>().addComment(NativeComment(author: 'कारीगर', message: languageCode == 'hi' ? 'धन्यवाद, आपकी बात सुनी गई।' : 'Thank you, your feedback has been heard.', languageCode: languageCode)),
        icon: const Icon(Icons.mic_rounded),
        label: Text(hindi ? 'बोलकर जवाब दें' : 'Reply by voice'),
      );
}

class _VoiceDock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceController>();
    final product = context.watch<ProductController>();
    final user = context.watch<AuthController>().identity;
    return Column(children: <Widget>[
      MagneticVoiceButton(onPressed: voice.toggleListening),
      const SizedBox(height: 10),
      Text(voice.mode == VoiceMode.listening ? 'Say a command, for example: change price to 500' : voice.lastTranscript.isEmpty ? 'Speak — I am listening' : voice.lastTranscript, textAlign: TextAlign.center),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: user == null || product.isPublishing ? null : () => product.publish(user.uid),
        icon: product.isPublishing ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.rocket_launch_rounded),
        label: Text(product.isPublishing ? 'Publishing…' : 'Publish your craft'),
        style: FilledButton.styleFrom(backgroundColor: KalaColors.leaf, minimumSize: const Size.fromHeight(55)),
      ),
      if (product.publishError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(product.publishError!, textAlign: TextAlign.center, style: const TextStyle(color: KalaColors.terracotta))),
    ]);
  }
}

class _InkPanel extends StatelessWidget {
  const _InkPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .76), borderRadius: BorderRadius.circular(27), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x15533C20), offset: Offset(0, 10), blurRadius: 20)]),
        child: child,
      );
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: <Widget>[Icon(icon, color: KalaColors.terracotta), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]);
}
