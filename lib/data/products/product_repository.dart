import '../../models/product_payload.dart';

abstract class ProductRepository {
  Stream<List<ProductPayload>> watchProducts(String artisanId);
  Stream<List<ProductPayload>> watchMarketplaceProducts();
  Future<ProductPayload> publish({required String artisanId, required ProductPayload product});
}
