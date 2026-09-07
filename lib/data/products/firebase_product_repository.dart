import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../models/product_payload.dart';
import '../../services/imgbb_upload_service.dart';
import 'product_repository.dart';

class FirebaseProductRepository implements ProductRepository {
  FirebaseProductRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImgbbUploadService? imgbb,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _imgbb = imgbb ?? ImgbbUploadService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImgbbUploadService _imgbb;

  CollectionReference<Map<String, dynamic>> _products(String artisanId) =>
      _firestore.collection('artisans').doc(artisanId).collection('products');

  @override
  Stream<List<ProductPayload>> watchProducts(String artisanId) => _products(artisanId)
      .snapshots()
      .map((snapshot) {
        final products = snapshot.docs
            .map((document) => ProductPayload.fromJson(<String, dynamic>{...document.data(), 'id': document.id}))
            .toList();
        // Sort in-memory to prevent composite index and serverTimestamp errors
        products.sort((a, b) => b.id.compareTo(a.id));
        return List<ProductPayload>.unmodifiable(products);
      })
      .handleError((e) {
        debugPrint('[FirebaseProductRepository] watchProducts error: $e');
        return const <ProductPayload>[];
      });

  @override
  Stream<List<ProductPayload>> watchMarketplaceProducts() {
    return _firestore
        .collection('products')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      final products = docs.map((document) {
        final data = document.data();
        return ProductPayload.fromJson(<String, dynamic>{...data, 'id': document.id});
      }).toList();

      // Sort in-memory to prevent index errors
      products.sort((a, b) => b.id.compareTo(a.id));
      return List<ProductPayload>.unmodifiable(products);
    }).handleError((e) {
      debugPrint('[FirebaseProductRepository] watchMarketplaceProducts error: $e');
      return const <ProductPayload>[];
    });
  }

  @override
  Future<ProductPayload> publish({required String artisanId, required ProductPayload product}) async {
    final heroImage = await _uploadIfLocal(artisanId: artisanId, productId: product.id, path: product.heroImagePath, ordinal: 'hero');
    final additionalImages = <String>[];
    for (var index = 0; index < product.additionalImages.length; index++) {
      additionalImages.add(await _uploadIfLocal(artisanId: artisanId, productId: product.id, path: product.additionalImages[index], ordinal: 'gallery-$index'));
    }
    final remote = product.copyWith(heroImagePath: heroImage, additionalImages: additionalImages);
    final payload = <String, Object?>{
      ...remote.toJson(),
      'artisanId': artisanId,
      'updatedAt': FieldValue.serverTimestamp(),
      'publishedAt': FieldValue.serverTimestamp(),
    };

    try {
      // 1. Save to artisan subcollection
      await _products(artisanId).doc(remote.id).set(payload, SetOptions(merge: true));
      // 2. Save to top-level products collection for immediate home marketplace feed
      await _firestore.collection('products').doc(remote.id).set(payload, SetOptions(merge: true));
      debugPrint('✨ [FirebaseProductRepository] Product ${remote.id} published successfully to both collections.');
    } catch (e) {
      debugPrint('[FirebaseProductRepository] Error setting Firestore documents: $e');
      rethrow;
    }

    return remote;
  }

  Future<String> _uploadIfLocal({
    required String artisanId,
    required String productId,
    required String path,
    required String ordinal,
  }) async {
    if (path.startsWith('http')) return path;
    final file = File(path);
    if (!await file.exists()) return path;

    // 1. Try ImgBB upload using user's API key
    try {
      final imgbbUrl = await _imgbb.uploadImageFile(file);
      if (imgbbUrl != null && imgbbUrl.startsWith('http')) {
        return imgbbUrl;
      }
    } catch (e) {
      debugPrint('[FirebaseProductRepository] ImgBB upload failed, falling back: $e');
    }

    // 2. Fallback to Firebase Storage
    try {
      final reference = _storage.ref('artisans/$artisanId/products/$productId/$ordinal.jpg');
      await reference.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      return await reference.getDownloadURL();
    } catch (e) {
      debugPrint('[FirebaseProductRepository] Firebase Storage upload skipped or failed: $e');
    }

    // 3. Graceful fallback: return original local path rather than aborting publishing
    return path;
  }
}
