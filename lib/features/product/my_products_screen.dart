import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/products/product_repository.dart';
import '../../l10n/app_copy.dart';
import '../../models/product_payload.dart';
import '../../state/auth_controller.dart';
import '../../state/app_flow_controller.dart';
import '../../state/product_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';

/// Live catalog of the signed-in artisan's published Firestore products.
class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final artisanId = context.read<AuthController>().identity!.uid;
    final copy = AppCopy.forLanguage(context.watch<AppFlowController>().profile?.languageCode);
    return Scaffold(
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: StreamBuilder<List<ProductPayload>>(
            stream: context.read<ProductRepository>().watchProducts(artisanId),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <ProductPayload>[];
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded)),
                    title: Text(copy.myArt, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  if (snapshot.hasError)
                    const SliverFillRemaining(child: Center(child: Text('Products could not be loaded. Please try again.')))
                  else if (items.isEmpty)
                    const SliverFillRemaining(child: _EmptyProducts())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 13),
                        itemBuilder: (context, index) => _ProductPreview(product: items[index]),
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

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(35),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Icon(Icons.auto_awesome_mosaic_rounded, size: 86, color: KalaColors.terracotta),
          SizedBox(height: 18),
          Text('आपकी पहली कला का इंतज़ार है', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          SizedBox(height: 9),
          Text('डैशबोर्ड से “कला स्कैन करें” दबाइए।', textAlign: TextAlign.center),
        ]),
      );
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview({required this.product});
  final ProductPayload product;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          context.read<ProductController>().hydrateFromAiPayload(Map<String, dynamic>.from(product.toJson()));
          Navigator.of(context).pop();
        },
        child: Container(
          height: 126,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .78), borderRadius: BorderRadius.circular(25), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x14543A1C), blurRadius: 18, offset: Offset(0, 8))]),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(25)),
                child: _ProductImage(path: product.heroImagePath),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text(
                        '₹${product.suggestedPrice}',
                        style: const TextStyle(color: KalaColors.leaf, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    const fallback = SizedBox(
      width: 122,
      child: Icon(Icons.palette_rounded, size: 40),
    );
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 122,
        height: 126,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.file(
      File(path),
      width: 122,
      height: 126,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
