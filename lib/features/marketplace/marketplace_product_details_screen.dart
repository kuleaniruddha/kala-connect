import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_payload.dart';
import '../../state/app_flow_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_and_orders_controller.dart';
import '../../state/voice_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';
import '../../widgets/artisan_follow_button.dart';
import 'checkout_bottom_sheet.dart';

class MarketplaceProductDetailsScreen extends StatefulWidget {
  const MarketplaceProductDetailsScreen({required this.product, super.key});

  final ProductPayload product;

  @override
  State<MarketplaceProductDetailsScreen> createState() => _MarketplaceProductDetailsScreenState();
}

class _MarketplaceProductDetailsScreenState extends State<MarketplaceProductDetailsScreen> {
  int _selectedImageIndex = 0;
  bool _showCleanStudio = true;

  List<String> get _allImages {
    final list = <String>[widget.product.heroImagePath];
    list.addAll(widget.product.additionalImages);
    return list;
  }

  bool _isOwnProduct(BuildContext context) {
    final auth = context.watch<AuthController>();
    final appFlow = context.watch<AppFlowController>();
    final currentUserId = auth.identity?.uid;
    final currentProfileName = appFlow.profile?.name.trim().toLowerCase();
    final productArtisanName = widget.product.artisanName.trim().toLowerCase();

    return currentUserId != null && (
      (widget.product.artisanId.isNotEmpty &&
          (currentUserId == widget.product.artisanId || appFlow.isBoundTo(widget.product.artisanId))) ||
      (currentProfileName != null &&
          currentProfileName.isNotEmpty &&
          currentProfileName == productArtisanName)
    );
  }

  void _handleAddToCart() {
    if (_isOwnProduct(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot purchase or add your own listed craft to cart.'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }
    context.read<CartAndOrdersController>().addToCart(widget.product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${widget.product.name}" to cart!'),
        backgroundColor: KalaColors.leaf,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _handleBuyNow() async {
    if (_isOwnProduct(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot purchase your own listed craft.'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }
    final order = await CheckoutBottomSheet.show(context, directBuyProduct: widget.product);
    if (order != null && mounted) {
      showDialog<void>(
        context: context,
        builder: (alertCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: KalaColors.leaf, size: 28),
              SizedBox(width: 8),
              Text('Order Placed!', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: Text(
            'Thank you! Your order #${order.orderId} for "${widget.product.name}" has been placed directly with artisan ${widget.product.artisanName}.\n\nTracking: ${order.trackingNumber}',
            style: const TextStyle(height: 1.3),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(alertCtx).pop(),
              style: FilledButton.styleFrom(backgroundColor: KalaColors.terracotta),
              child: const Text('Track Order'),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final images = _allImages;
    final currentImagePath = images[_selectedImageIndex.clamp(0, images.length - 1)];

    return Scaffold(
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Amazon-style Top Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: KalaColors.ink),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: KalaColors.ink),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing link to this authentic Indian craft...')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border_rounded, color: KalaColors.terracotta),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved to your craft wishlist!')),
                      );
                    },
                  ),
                ],
              ),

              // Gallery Carousel with Studio clean toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Studio badge & toggle
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: KalaColors.terracotta.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: KalaColors.terracotta, size: 14),
                                SizedBox(width: 4),
                                Text('GI Tag & Artisan Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: KalaColors.terracotta)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Text('AI Studio Clean:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Switch.adaptive(
                            value: _showCleanStudio,
                            activeTrackColor: KalaColors.terracotta,
                            activeThumbColor: Colors.white,
                            onChanged: (val) => setState(() => _showCleanStudio = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Main Zoom Image
                      Container(
                        height: 320,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _showCleanStudio ? const Color(0xFFFDFBF7) : Colors.black12,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: _showCleanStudio
                              ? const [
                                  BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 10)),
                                ]
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Center(
                          child: _buildProductImage(currentImagePath, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Image Thumbnails Rail
                      if (images.length > 1)
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final isSelected = _selectedImageIndex == index;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedImageIndex = index),
                                child: Container(
                                  width: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? KalaColors.terracotta : Colors.black12,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _buildProductImage(images[index], fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Product Title
                      Text(
                        p.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: KalaColors.ink, height: 1.2),
                      ),
                      const SizedBox(height: 8),

                      // Artisan Profile Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: KalaColors.terracotta,
                              child: Text(
                                p.artisanName.isNotEmpty ? p.artisanName[0] : 'A',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.artisanName,
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, color: KalaColors.leaf, size: 16),
                                    ],
                                  ),
                                  Text(
                                    p.artisanLocation,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B6572), fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ArtisanFollowButton(
                              artisanId: p.artisanId,
                              artisanName: p.artisanName,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Ratings & Reviews
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: KalaColors.leaf, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Text('${p.rating}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                const SizedBox(width: 3),
                                const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${p.reviewCount} verified buyer ratings', style: const TextStyle(color: Color(0xFF6B6572), fontWeight: FontWeight.w600, fontSize: 13)),
                          const Spacer(),
                          const Text('FREE Delivery', style: TextStyle(color: KalaColors.leaf, fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Price Block
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('₹${p.suggestedPrice}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: KalaColors.ink)),
                          const SizedBox(width: 10),
                          Text('M.R.P. ₹${p.effectiveMrp}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black45, fontSize: 16)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: KalaColors.terracotta.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text('${p.discountPercent}% OFF', style: const TextStyle(color: KalaColors.terracotta, fontWeight: FontWeight.w900, fontSize: 13)),
                          ),
                        ],
                      ),
                      const Text('Inclusive of all taxes • 100% goes directly to the artisan family', style: TextStyle(fontSize: 12, color: Color(0xFF6B6572))),
                      const SizedBox(height: 20),

                      // Transparent Fair Price breakdown card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: KalaColors.turmeric.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: KalaColors.turmeric.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.balance_rounded, color: KalaColors.ink, size: 20),
                                SizedBox(width: 8),
                                Text('₹ AI Transparent Fair Price Breakdown', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Market Range: ₹${p.priceLow} – ₹${p.priceHigh}\nPrimary Material: ${p.material}\nYour purchase ensures the rural craft cluster sustains its generational livelihood.',
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Craft Description & Story
                      const Text('About this Craft / कला का विवरण', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(p.description, style: const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF2C2238))),
                      const SizedBox(height: 16),

                      // Technical / Heritage Details
                      if (p.moreInfo.isNotEmpty) ...[
                        const Text('Heritage Details & Specifications:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(p.moreInfo, style: const TextStyle(fontSize: 13, height: 1.35)),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Customer Reviews with Voice Listen
                      Row(
                        children: [
                          const Text('Customer Reviews / ग्राहकों की राय', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, color: KalaColors.indigo),
                            tooltip: 'Listen to customer feedback',
                            onPressed: context.read<VoiceController>().readCommentInsights,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...p.comments.map((comment) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.account_circle_rounded, color: Colors.black38, size: 20),
                                    const SizedBox(width: 6),
                                    Text(comment.author, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: KalaColors.leaf.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Verified Buyer', style: TextStyle(fontSize: 10, color: KalaColors.leaf, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(comment.message, style: const TextStyle(fontSize: 14, height: 1.3)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 80), // Padding for sticky bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isOwnProduct(context)) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is your listed craft. Self-purchase is disabled.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isOwnProduct(context) ? null : _handleAddToCart,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(
                        color: _isOwnProduct(context) ? Colors.grey.shade300 : KalaColors.terracotta,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledForegroundColor: Colors.grey.shade400,
                    ),
                    icon: Icon(
                      Icons.add_shopping_cart_rounded,
                      color: _isOwnProduct(context) ? Colors.grey.shade400 : KalaColors.terracotta,
                    ),
                    label: Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _isOwnProduct(context) ? Colors.grey.shade400 : KalaColors.terracotta,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isOwnProduct(context) ? null : _handleBuyNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isOwnProduct(context) ? Colors.grey.shade300 : KalaColors.terracotta,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(
                      Icons.flash_on_rounded,
                      color: _isOwnProduct(context) ? Colors.grey.shade500 : Colors.white,
                    ),
                    label: Text(
                      'Buy Now',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: _isOwnProduct(context) ? Colors.grey.shade500 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_rounded, size: 40)),
      );
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_rounded, size: 40)),
    );
  }
}
