import 'package:flutter_test/flutter_test.dart';
import 'package:kala_connect/data/products/local_product_repository.dart';
import 'package:kala_connect/state/product_controller.dart';

void main() {
  test('structured AI payload hydrates a product and price edits update it', () {
    final controller = ProductController(LocalProductRepository());
    controller.hydrateFromAiPayload(<String, dynamic>{
      'id': 'craft-1',
      'heroImagePath': '/tmp/craft.jpg',
      'description': 'A handwoven basket.',
      'suggestedPrice': 300,
      'tags': <String>['bamboo'],
      'moreInfo': 'Made by hand.',
      'additionalImages': const <String>[],
      'comments': const <Map<String, String>>[],
    });

    controller.changePrice(500);

    expect(controller.product?.suggestedPrice, 500);
    expect(controller.product?.description, 'A handwoven basket.');
  });
}
