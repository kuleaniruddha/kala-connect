import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/products/product_repository.dart';
import '../../models/product_payload.dart';
import '../../state/locale_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';
import 'marketplace_product_details_screen.dart';

class CategoriesExplorerScreen extends StatefulWidget {
  const CategoriesExplorerScreen({super.key});

  @override
  State<CategoriesExplorerScreen> createState() => _CategoriesExplorerScreenState();
}

class _CategoriesExplorerScreenState extends State<CategoriesExplorerScreen> {
  String? _selectedCategory;

  static const _craftThemes = [
    {
      'title': 'Terracotta & Clay',
      'subtitle': 'Panchmura, Bankura, Gorakhpur',
      'icon': Icons.terrain_rounded,
      'color': KalaColors.terracotta,
      'image': 'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Folk Paintings',
      'subtitle': 'Madhubani, Pattachitra, Warli',
      'icon': Icons.palette_rounded,
      'color': KalaColors.indigo,
      'image': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Metal & Brass',
      'subtitle': 'Bastar Dhokra, Moradabad Brass',
      'icon': Icons.hardware_rounded,
      'color': KalaColors.turmeric,
      'image': 'https://images.unsplash.com/photo-1606722590583-3caa991d0bdf?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Textiles & Handloom',
      'subtitle': 'Kantha, Kanchipuram, Chanderi',
      'icon': Icons.checkroom_rounded,
      'color': Color(0xFFC8395E),
      'image': 'https://images.unsplash.com/photo-1603204077779-bed963ea7d0d?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Wooden Craft',
      'subtitle': 'Channapatna, Saharanpur Teak',
      'icon': Icons.forest_rounded,
      'color': KalaColors.leaf,
      'image': 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Pottery & Ceramics',
      'subtitle': 'Jaipur Blue Pottery, Khurja',
      'icon': Icons.water_damage_rounded,
      'color': Color(0xFF2B7A78),
      'image': 'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=600&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _selectedCategory == null ? loc.tr('tab_categories') : _selectedCategory!,
          style: const TextStyle(fontWeight: FontWeight.w900, color: KalaColors.ink),
        ),
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _selectedCategory = null),
              )
            : null,
      ),
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: _selectedCategory == null
              ? _buildCategoryGrid()
              : _buildFilteredProducts(_selectedCategory!),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: _craftThemes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final theme = _craftThemes[index];
        final color = theme['color'] as Color;

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = theme['title'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          theme['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: color.withValues(alpha: 0.2)),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                          child: Icon(theme['icon'] as IconData, size: 16, color: color),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(theme['title'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, height: 1.2)),
                      const SizedBox(height: 3),
                      Text(theme['subtitle'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF6B6572), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilteredProducts(String category) {
    return StreamBuilder<List<ProductPayload>>(
      stream: context.read<ProductRepository>().watchMarketplaceProducts(),
      builder: (context, snapshot) {
        final list = (snapshot.data ?? const <ProductPayload>[])
            .where((p) => p.category.toLowerCase().contains(category.toLowerCase()))
            .toList();

        if (list.isEmpty) {
          return Center(
            child: Text('No crafts found in $category yet.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = list[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => MarketplaceProductDetailsScreen(product: product)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: product.heroImagePath.startsWith('http')
                          ? Image.network(product.heroImagePath, width: 85, height: 85, fit: BoxFit.cover)
                          : Image.file(File(product.heroImagePath), width: 85, height: 85, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          const SizedBox(height: 3),
                          Text('By ${product.artisanName} • ${product.artisanLocation}', style: const TextStyle(color: Color(0xFF6B6572), fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('₹${product.suggestedPrice}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: KalaColors.ink)),
                              const SizedBox(width: 6),
                              Text('₹${product.effectiveMrp}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black38, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
