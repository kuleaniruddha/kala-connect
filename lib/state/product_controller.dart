import 'package:flutter/foundation.dart';

import '../data/products/product_repository.dart';
import '../models/product_payload.dart';

class ProductController extends ChangeNotifier {
  ProductController(this._repository);

  final ProductRepository _repository;
  ProductPayload? _product;
  bool _isHydrating = false;
  bool _isPublishing = false;
  String? _publishError;

  ProductPayload? get product => _product;
  bool get isHydrating => _isHydrating;
  bool get isPublishing => _isPublishing;
  String? get publishError => _publishError;

  /// The direct JSON entrypoint for YOLO/TFLite + cloud enrichment output.
  void hydrateFromAiPayload(Map<String, dynamic> payload) {
    _isHydrating = true;
    notifyListeners();
    _product = ProductPayload.fromJson(payload);
    _isHydrating = false;
    notifyListeners();
  }

  void changePrice(int rupees) {
    if (_product == null || rupees < 1) return;
    _product = _product!.copyWith(suggestedPrice: rupees);
    notifyListeners();
  }

  void addComment(NativeComment comment) {
    if (_product == null || comment.message.isEmpty) return;
    _product = _product!.copyWith(comments: <NativeComment>[..._product!.comments, comment]);
    notifyListeners();
  }

  void addAdditionalImages(List<String> paths) {
    if (_product == null || paths.isEmpty) return;
    _product = _product!.copyWith(
      additionalImages: <String>{..._product!.additionalImages, ...paths}.toList(growable: false),
    );
    notifyListeners();
  }

  void appendMoreInfo(String information) {
    final trimmed = information.trim();
    if (_product == null || trimmed.isEmpty) return;
    final separator = _product!.moreInfo.trim().isEmpty ? '' : '\n';
    _product = _product!.copyWith(moreInfo: '${_product!.moreInfo}$separator$trimmed');
    notifyListeners();
  }

  void removeAdditionalImage(int zeroBasedIndex) {
    if (_product == null || zeroBasedIndex < 0 || zeroBasedIndex >= _product!.additionalImages.length) return;
    final images = List<String>.from(_product!.additionalImages)..removeAt(zeroBasedIndex);
    _product = _product!.copyWith(additionalImages: images);
    notifyListeners();
  }

  void clear() {
    _product = null;
    notifyListeners();
  }

  Future<void> publish(String artisanId) async {
    final product = _product;
    if (product == null || _isPublishing) return;
    _isPublishing = true;
    _publishError = null;
    notifyListeners();
    try {
      _product = await _repository.publish(artisanId: artisanId, product: product);
    } catch (error) {
      _publishError = error.toString();
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }
}
