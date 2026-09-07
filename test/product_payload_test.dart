import 'package:flutter_test/flutter_test.dart';
import 'package:kala_connect/models/product_payload.dart';

void main() {
  test('AI payload preserves all strict product-template sections', () {
    final product = ProductPayload.fromJson(<String, dynamic>{
      'id': 'craft-1',
      'heroImagePath': '/tmp/craft.jpg',
      'description': 'Handwoven bamboo basket.',
      'suggestedPrice': 500,
      'tags': <String>['bamboo'],
      'moreInfo': 'Made in Assam.',
      'additionalImages': <String>['/tmp/detail.jpg'],
      'comments': <Map<String, String>>[
        <String, String>{'author': 'Buyer', 'message': 'Beautiful', 'languageCode': 'en'},
      ],
    });

    expect(product.heroImagePath, '/tmp/craft.jpg');
    expect(product.suggestedPrice, 500);
    expect(product.additionalImages, hasLength(1));
    expect(product.comments.single.message, 'Beautiful');
  });
}
