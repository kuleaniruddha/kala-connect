import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/products/product_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product_payload.dart';
import '../../state/app_flow_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_and_orders_controller.dart';
import '../../state/locale_controller.dart';
import '../../state/voice_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';
import '../artisan/join_artist_flow.dart';
import '../auth/email_auth_dialog.dart';
import 'marketplace_product_details_screen.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({
    required this.onOpenStudio,
    required this.onOpenCart,
    required this.onOpenProfile,
    super.key,
  });

  final VoidCallback onOpenStudio;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenProfile;

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategoryKey = 'all';
  String _searchQuery = '';

  static const _categoryKeys = [
    'all',
    'cat_terracotta',
    'cat_paintings',
    'cat_metal',
    'cat_textiles',
    'cat_wood',
    'cat_pottery',
  ];

  static const _categoryEnglishKeywords = {
    'all': '',
    'cat_terracotta': 'terracotta',
    'cat_paintings': 'painting',
    'cat_metal': 'brass',
    'cat_textiles': 'textile',
    'cat_wood': 'wood',
    'cat_pottery': 'pottery',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startVoiceSearch() {
    final voice = context.read<VoiceController>();
    voice.toggleListening();

    void listener() {
      if (!mounted) return;
      final transcript = voice.lastTranscript;
      if (transcript.isNotEmpty) {
        setState(() {
          _searchController.text = transcript;
          _searchQuery = transcript.toLowerCase();
        });
      }
    }

    voice.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartAndOrdersController>();
    final voice = context.watch<VoiceController>();
    final loc = context.watch<LocaleController>();

    return Scaffold(
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: StreamBuilder<List<ProductPayload>>(
            stream: context.read<ProductRepository>().watchMarketplaceProducts(),
            builder: (context, snapshot) {
              final allProducts = snapshot.data ?? const <ProductPayload>[];

              // Filter by category and search
              final targetKeyword = _categoryEnglishKeywords[_selectedCategoryKey] ?? '';
              final searchWords = _searchQuery.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

              final filteredProducts = allProducts.where((p) {
                final matchesCategory = _selectedCategoryKey == 'all' ||
                    p.category.toLowerCase().contains(targetKeyword);
                if (!matchesCategory) return false;
                if (searchWords.isEmpty) return true;

                final corpus = '${p.name} ${p.description} ${p.category} ${p.artisanName} ${p.artisanLocation} ${p.tags.join(" ")}'.toLowerCase();
                return searchWords.every((word) => corpus.contains(word));
              }).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Amazon-style Search Header & Language Quick Switcher
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [KalaColors.terracotta, Color(0xFFC8395E)]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.palette_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(loc.tr('app_name'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                  ],
                                ),
                              ),
                              const Spacer(),

                              // Quick Language Switcher Dropdown
                              PopupMenuButton<String>(
                                initialValue: loc.languageCode,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                onSelected: (code) => loc.setLanguage(code),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: KalaColors.terracotta.withValues(alpha: 0.3)),
                                    boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4)],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.translate_rounded, color: KalaColors.terracotta, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.supportedLanguages
                                            .firstWhere((l) => l['code'] == loc.languageCode, orElse: () => {'name': 'हिंदी'})['name']!,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KalaColors.ink),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: KalaColors.ink, size: 18),
                                    ],
                                  ),
                                ),
                                itemBuilder: (_) => AppLocalizations.supportedLanguages.map((lang) {
                                  return PopupMenuItem<String>(
                                    value: lang['code'],
                                    child: Text(
                                      '${lang['name']} (${lang['englishName']})',
                                      style: TextStyle(
                                        fontWeight: lang['code'] == loc.languageCode ? FontWeight.w900 : FontWeight.w500,
                                        color: lang['code'] == loc.languageCode ? KalaColors.terracotta : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(width: 6),

                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.shopping_cart_outlined, color: KalaColors.ink),
                                    onPressed: widget.onOpenCart,
                                  ),
                                  if (cart.totalItemCount > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: KalaColors.terracotta, shape: BoxShape.circle),
                                        child: Text(
                                          '${cart.totalItemCount}',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(color: Color(0x101A1720), blurRadius: 14, offset: Offset(0, 4)),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                              decoration: InputDecoration(
                                hintText: loc.tr('search_hint'),
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8B8592)),
                                prefixIcon: const Icon(Icons.search_rounded, color: KalaColors.terracotta),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_searchQuery.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        voice.mode == VoiceMode.listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                        color: voice.mode == VoiceMode.listening ? Colors.red : KalaColors.terracotta,
                                      ),
                                      tooltip: 'Search by voice',
                                      onPressed: _startVoiceSearch,
                                    ),
                                  ],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Pincode Delivery Bar
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: KalaColors.leaf),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${loc.tr('delivery_to')} Mumbai 400001 • ${loc.tr('dispatch_direct')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4A3525)),
                                ),
                              ),
                            ],
                          ),

                          // Popular Craft Suggestion Chips when search is empty
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  'Terracotta',
                                  'Madhubani',
                                  'Dhokra Brass',
                                  'Handloom',
                                  'Channapatna Wood',
                                  'Blue Pottery',
                                ].map((tag) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ActionChip(
                                        label: Text(tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: Colors.grey.shade300),
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        onPressed: () {
                                          _searchController.text = tag;
                                          setState(() => _searchQuery = tag.toLowerCase());
                                        },
                                      ),
                                    )).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Search Result Notice Bar when query is active
                  if (_searchQuery.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: KalaColors.terracotta.withValues(alpha: 0.25)),
                            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: KalaColors.terracotta, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Showing results for "$_searchQuery" (${filteredProducts.length} crafts)',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: KalaColors.ink),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: KalaColors.terracotta.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Clear', style: TextStyle(color: KalaColors.terracotta, fontWeight: FontWeight.w900, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Festival / Sales Carousel Banner (Shown when not searching)
                  if (_searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE85D3F), Color(0xFF8D2B4A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33E85D3F), blurRadius: 16, offset: Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: KalaColors.turmeric, borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                        loc.tr('hero_tag'),
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: KalaColors.ink),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.tr('hero_title'),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loc.tr('hero_subtitle'),
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                                child: const Icon(Icons.local_mall_rounded, color: Colors.white, size: 36),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Dedicated "Are you an Artisan? Sell with AI Studio" Card (Gated on Login)
                  if (_searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2A2038), Color(0xFF443152)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: KalaColors.turmeric.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, color: KalaColors.turmeric, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.tr('artisan_banner_title'),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                                    Text(
                                      loc.tr('artisan_banner_sub'),
                                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () async {
                                  final auth = context.read<AuthController>();
                                  if (!auth.isSignedIn) {
                                    final signedIn = await EmailAuthDialog.show(context);
                                    if (!context.mounted || !signedIn) return;
                                  }

                                  final appFlow = context.read<AppFlowController>();
                                  final isArtisan = appFlow.profile?.isArtisan ?? false;
                                  if (!isArtisan) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const JoinArtistFlow(),
                                      ),
                                    );
                                  } else {
                                    widget.onOpenStudio();
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: KalaColors.terracotta,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  loc.tr('artisan_banner_btn'),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Horizontal Category Pills
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categoryKeys.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final key = _categoryKeys[index];
                          final isSelected = _selectedCategoryKey == key;
                          final displayName = loc.tr(key);
                          return ChoiceChip(
                            label: Text(displayName, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700)),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCategoryKey = key),
                            selectedColor: KalaColors.terracotta,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : KalaColors.ink),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: isSelected ? Colors.transparent : Colors.black12),
                          );
                        },
                      ),
                    ),
                  ),

                  // Featured Sales Rail (Shown when not searching)
                  if (_searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(loc.tr('deals_of_day'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: KalaColors.ink)),
                            TextButton(
                              onPressed: () {},
                              child: Text(loc.tr('view_all'), style: const TextStyle(color: KalaColors.terracotta, fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 2-Column Amazon Product Grid
                  if (filteredProducts.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('No crafts found matching your search. Try another query!'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.52,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = filteredProducts[index];
                            return _MarketplaceCard(
                              product: product,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => MarketplaceProductDetailsScreen(product: product),
                                  ),
                                );
                              },
                              onAddToCart: () {
                                cart.addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added "${product.name}" to cart!'),
                                    backgroundColor: KalaColors.leaf,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: filteredProducts.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  const _MarketplaceCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  final ProductPayload product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleController>();
    final auth = context.watch<AuthController>();
    final appFlow = context.watch<AppFlowController>();
    final currentUserId = auth.identity?.uid;
    final currentProfileName = appFlow.profile?.name.trim().toLowerCase();
    final productArtisanName = product.artisanName.trim().toLowerCase();

    final isOwnProduct = currentUserId != null && (
      (product.artisanId.isNotEmpty &&
          (currentUserId == product.artisanId || appFlow.isBoundTo(product.artisanId))) ||
      (currentProfileName != null &&
          currentProfileName.isNotEmpty &&
          currentProfileName == productArtisanName)
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x0D1A1720), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Discount Tag
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 1.22,
                    child: _buildImage(product.heroImagePath),
                  ),
                ),
                if (product.discountPercent > 0)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: KalaColors.terracotta,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.discountPercent}% OFF',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, height: 1.2, color: KalaColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.artisanName} • ${product.artisanLocation}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),

                  // Rating Row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${product.suggestedPrice}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: KalaColors.ink),
                      ),
                      const SizedBox(width: 5),
                      if (product.mrp != null && product.mrp! > product.suggestedPrice)
                        Text(
                          '₹${product.mrp}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: isOwnProduct ? null : onAddToCart,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(
                          color: isOwnProduct ? Colors.grey.shade300 : KalaColors.terracotta,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        disabledForegroundColor: Colors.grey.shade400,
                      ),
                      icon: Icon(
                        isOwnProduct ? Icons.check_circle_outline_rounded : Icons.add_shopping_cart_rounded,
                        size: 14,
                        color: isOwnProduct ? Colors.grey.shade400 : KalaColors.terracotta,
                      ),
                      label: Text(
                        isOwnProduct ? 'Your Craft' : loc.tr('add_to_cart'),
                        style: TextStyle(
                          color: isOwnProduct ? Colors.grey.shade400 : KalaColors.terracotta,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: Colors.amber.shade100,
      child: const Center(
        child: Icon(Icons.brush_rounded, size: 40, color: KalaColors.terracotta),
      ),
    );
  }
}
