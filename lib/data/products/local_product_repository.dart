import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/product_payload.dart';
import 'product_repository.dart';

/// Offline/demo product cache. Firestore provides its own offline cache after a
/// Firebase project is configured; this keeps the local development flow real.
class LocalProductRepository implements ProductRepository {
  final StreamController<List<ProductPayload>> _changes =
      StreamController<List<ProductPayload>>.broadcast();

  final StreamController<List<ProductPayload>> _marketplaceChanges =
      StreamController<List<ProductPayload>>.broadcast();

  String _key(String artisanId) => 'local_products_$artisanId';
  static const _marketplaceIndexKey = 'local_marketplace_index';

  @override
  Future<ProductPayload> publish({
    required String artisanId,
    required ProductPayload product,
  }) async {
    final items = await _load(artisanId);
    items.removeWhere((item) => item.id == product.id);
    items.add(product);
    await _save(artisanId, items);
    _changes.add(List<ProductPayload>.unmodifiable(items));

    // Also update global marketplace catalog
    final allMarketplace = await _loadAllMarketplace();
    allMarketplace.removeWhere((item) => item.id == product.id);
    allMarketplace.insert(0, product);
    await _saveMarketplace(allMarketplace);
    _marketplaceChanges.add(List<ProductPayload>.unmodifiable(allMarketplace));

    return product;
  }

  @override
  Stream<List<ProductPayload>> watchProducts(String artisanId) async* {
    yield List<ProductPayload>.unmodifiable(await _load(artisanId));
    yield* _changes.stream;
  }

  @override
  Stream<List<ProductPayload>> watchMarketplaceProducts() async* {
    yield List<ProductPayload>.unmodifiable(await _loadAllMarketplace());
    yield* _marketplaceChanges.stream;
  }

  Future<List<ProductPayload>> _loadAllMarketplace() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_marketplaceIndexKey);
    if (raw == null || raw.isEmpty) {
      return <ProductPayload>[];
    }
    return raw
        .map((value) => ProductPayload.fromJson(jsonDecode(value) as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _saveMarketplace(List<ProductPayload> products) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _marketplaceIndexKey,
      products.map((product) => jsonEncode(product.toJson())).toList(growable: false),
    );
  }

  Future<List<ProductPayload>> _load(String artisanId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_key(artisanId)) ?? const <String>[];
    return raw
        .map((value) =>
            ProductPayload.fromJson(jsonDecode(value) as Map<String, dynamic>))
        .toList(growable: true);
  }

  Future<void> _save(String artisanId, List<ProductPayload> products) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key(artisanId),
      products
          .map((product) => jsonEncode(product.toJson()))
          .toList(growable: false),
    );
  }
}
