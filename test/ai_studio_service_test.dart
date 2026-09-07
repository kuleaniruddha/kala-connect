import 'package:flutter_test/flutter_test.dart';
import 'package:kala_connect/services/ai_studio_service.dart';

void main() {
  test('AiStudioService pricing returns consistent fair wage and market range', () {
    final service = AiStudioService();

    // Terracotta pricing
    final terracottaPricing = service.estimatePricing(
      category: 'Terracotta & Clay',
      material: 'Alluvial Riverbed Clay',
      customLaborHours: 5,
    );

    expect(terracottaPricing.minSustainablePrice > 0, true);
    expect(terracottaPricing.recommendedPrice >= terracottaPricing.minSustainablePrice, true);
    expect(terracottaPricing.maxPremiumPrice >= terracottaPricing.recommendedPrice, true);
    expect(terracottaPricing.mrp > terracottaPricing.recommendedPrice, true);
    expect(terracottaPricing.discountPercent > 0, true);

    // Brass/Metal pricing has higher material and labor index
    final brassPricing = service.estimatePricing(
      category: 'Metal & Brass',
      material: 'Bell Metal Brass',
      customLaborHours: 8,
    );

    expect(brassPricing.recommendedPrice > terracottaPricing.recommendedPrice, true);
  });

  test('AiStudioService generates SEO catalog from Hindi voice transcript', () async {
    final service = AiStudioService();

    final result = await service.generateCatalog(
      voiceTranscriptOrText: 'मिट्टी का घोड़ा बांकुरा कला',
      artisanLocation: 'Panchmura, Bankura',
      artisanName: 'Biren Kumbhakar',
    );

    expect(result.category, 'Terracotta & Clay');
    expect(result.seoTitle.contains('Terracotta'), true);
    expect(result.englishDescription.isNotEmpty, true);
    expect(result.hindiDescription.isNotEmpty, true);
    expect(result.bulletPoints.length >= 4, true);
    expect(result.tags.contains('terracotta'), true);
  });

  test('AiStudioService generates SEO catalog from English voice transcript', () async {
    final service = AiStudioService();

    final result = await service.generateCatalog(
      voiceTranscriptOrText: 'Handmade madhubani painting with peacock on silk',
      artisanLocation: 'Madhubani, Bihar',
      artisanName: 'Ganga Devi',
    );

    expect(result.category, 'Folk Paintings');
    expect(result.seoTitle.contains('Madhubani'), true);
    expect(result.tags.contains('madhubani'), true);
  });

  test('AiStudioService recognizes pot and matka photo and categorizes into Pottery & Ceramics', () async {
    final service = AiStudioService();

    // User uploads a pot or speaks about a clay pot/matka
    final result = await service.generateCatalog(
      voiceTranscriptOrText: 'मिट्टी का घड़ा या मटका पानी के लिए',
      artisanLocation: 'Khurja, Uttar Pradesh',
      artisanName: 'Ramesh Kumar',
    );

    expect(result.category, 'Pottery & Ceramics');
    expect(result.seoTitle.contains('Clay Pot') || result.seoTitle.contains('Pottery'), true);
    expect(result.tags.contains('pottery') || result.tags.contains('clay_pot'), true);
    expect(result.englishDescription.toLowerCase().contains('clay'), true);
  });

  test('AiStudioService recognizes English pot/planter and categorizes into Pottery & Ceramics', () async {
    final service = AiStudioService();

    final result = await service.generateCatalog(
      voiceTranscriptOrText: 'Handmade ceramic garden pot and flowerpot planter',
      artisanLocation: 'Jaipur, Rajasthan',
      artisanName: 'Mohan Lal',
    );

    expect(result.category, 'Pottery & Ceramics');
    expect(result.tags.contains('pottery') || result.tags.contains('clay_pot'), true);
  });
}
