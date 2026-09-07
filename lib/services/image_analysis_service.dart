import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../models/product_payload.dart';

/// Runs Google's on-device ML Kit label model against a local camera/gallery
/// image. Enhanced with culturally nuanced recognition and simple voice descriptions
/// tailored specifically for illiterate and neo-literate Indian artisans.
class ImageAnalysisService {
  Future<ProductPayload> analyse({
    required String imagePath,
    required String languageCode,
    List<String> additionalImages = const <String>[],
  }) async {
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: .35),
    );
    try {
      final labels = await labeler.processImage(InputImage.fromFilePath(imagePath));
      final evidence = labels
          .where((label) => label.confidence >= .35)
          .toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      final tags = evidence
          .take(8)
          .map((label) => label.label.trim().toLowerCase())
          .where((label) => label.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final catalog = _catalogFor(tags);
      return ProductPayload(
        id: 'craft-${DateTime.now().microsecondsSinceEpoch}',
        heroImagePath: imagePath,
        name: catalog.name(languageCode),
        category: catalog.category,
        description: _description(catalog, tags, languageCode),
        suggestedPrice: catalog.suggested,
        priceLow: catalog.low,
        priceHigh: catalog.high,
        currency: 'INR',
        tags: tags,
        moreInfo: _spokenInsight(catalog, tags, languageCode),
        additionalImages: additionalImages,
        comments: const <NativeComment>[],
      );
    } finally {
      await labeler.close();
    }
  }

  _CatalogRule _catalogFor(List<String> tags) {
    final text = tags.join(' ');
    
    // Pottery, Terracotta & Ceramics
    if (RegExp(r'pottery|ceramic|vase|bowl|jug|pitcher|cup|earthen|clay|terracotta|mitti|urn|crockery|tableware|flowerpot|pot|planter|vessel|jar|matka|ghada|kulhad|gamla|handi|surahi').hasMatch(text)) {
      return const _CatalogRule(
        nameEn: 'Handcrafted Traditional Clay Pot & Pottery',
        nameHi: 'हस्तनिर्मित पारंपरिक मिट्टी का घड़ा व बर्तन',
        category: 'Pottery & Ceramics',
        materialEn: 'Natural Riverbed Clay & Terracotta Glaze',
        materialHi: 'प्राकृतिक चिकनी मिट्टी व टेराकोटा',
        low: 350,
        high: 1400,
      );
    }

    // Jewellery & Adornments
    if (RegExp(r'jewel|necklace|ring|bracelet|earring|bead|bangle|pendant|gem|ornament|accessory|silver|gold').hasMatch(text)) {
      return const _CatalogRule(
        nameEn: 'Handcrafted Heritage Artisan Jewellery',
        nameHi: 'हस्तनिर्मित पारंपरिक आभूषण',
        category: 'Jewellery & Accessories',
        materialEn: 'Hand-cast Metal & Traditional Beads',
        materialHi: 'पारंपरिक धातु व नक्काशीदार मनके',
        low: 600,
        high: 2500,
      );
    }

    // Handloom, Saree, Textiles & Embroidery
    if (RegExp(r'textile|fabric|clothing|dress|scarf|saree|shawl|linen|thread|embroidery|weave|woven|pattern|cotton|silk|apparel|blanket').hasMatch(text)) {
      return const _CatalogRule(
        nameEn: 'Traditional Handloom Artisan Weave',
        nameHi: 'पारंपरिक हथकरघा बुनाई व वस्त्र',
        category: 'Textiles & Handloom',
        materialEn: 'Pure Organic Cotton & Handloom Thread',
        materialHi: 'शुद्ध सूत एवं प्राकृतिक हथकरघा धागे',
        low: 500,
        high: 2200,
      );
    }

    // Metal, Brass & Dhokra
    if (RegExp(r'brass|metal|bronze|copper|statue|bell|sculpture|iron|figurine|dhokra|diya|antique').hasMatch(text)) {
      return const _CatalogRule(
        nameEn: 'Lost-Wax Brass & Bell Metal Craft',
        nameHi: 'पारंपरिक पीतल व ढोकरा धातु शिल्प',
        category: 'Metal & Brass',
        materialEn: 'Lost-wax Cast Brass & Bell Metal',
        materialHi: 'शुद्ध पीतल व कांस्य धातु',
        low: 750,
        high: 3200,
      );
    }

    // Woodcraft & Toys
    if (RegExp(r'wood|timber|carving|furniture|toy|mask|box|board|channapatna|carpentry').hasMatch(text)) {
      return const _CatalogRule(
        nameEn: 'Hand-Carved Wooden Artisan Craft',
        nameHi: 'लकड़ी पर नक्काशीदार हस्तशिल्प',
        category: 'Wooden Crafts',
        materialEn: 'Seasoned Natural Wood & Organic Polish',
        materialHi: 'प्राकृतिक लकड़ी व जैविक वार्निश',
        low: 400,
        high: 1800,
      );
    }

    // Bamboo, Cane & Wicker Weaving
    if (RegExp(r'basket|wicker|cane|bamboo|straw|mat|weave|hamper|container').hasMatch(text)) {
      return const _CatalogRule(
        nameEn: 'Handwoven Bamboo & Cane Basketry',
        nameHi: 'हाथ से बुनी बांस व बेंत की टोकरी',
        category: 'Bamboo & Cane',
        materialEn: 'Sun-dried Natural Bamboo & Cane Splints',
        materialHi: 'प्राकृतिक बांस व बेंत',
        low: 300,
        high: 1200,
      );
    }

    // Folk Paintings & Wall Art
    if (RegExp(r'painting|art|drawing|artwork|canvas|sketch|illustration|madhubani|warli|folk|picture').hasMatch(text)) {
      return const _CatalogRule(
        nameEn: 'Authentic Folk Heritage Painting',
        nameHi: 'पारंपरिक लोक चित्रकला धरोहर',
        category: 'Folk Paintings',
        materialEn: 'Handmade Canvas & Natural Plant Dyes',
        materialHi: 'हाथ का बना कैनवास व प्राकृतिक रंग',
        low: 800,
        high: 3500,
      );
    }

    // Stone Carving
    if (RegExp(r'stone|rock|marble|granite|sculpture|carved|masonry').hasMatch(text)) {
      return const _CatalogRule(
        nameEn: 'Hand-Carved Natural Stone Artifact',
        nameHi: 'प्राकृतिक पत्थर पर हस्तनिर्मित नक्काशी',
        category: 'Stone & Sculpture',
        materialEn: 'Soft Sandstone / Marble',
        materialHi: 'प्राकृतिक बलुआ पत्थर / संगमरमर',
        low: 550,
        high: 2600,
      );
    }

    // Default authentic craft
    return const _CatalogRule(
      nameEn: 'Authentic Handcrafted Artisan Craft',
      nameHi: 'प्रामाणिक पारंपरिक हस्तशिल्प उत्पाद',
      category: 'Traditional Handicrafts',
      materialEn: 'Locally Sourced Natural Materials',
      materialHi: 'स्थानीय प्राकृतिक कच्चा माल',
      low: 400,
      high: 1500,
    );
  }

  String _description(_CatalogRule catalog, List<String> tags, String languageCode) {
    if (languageCode == 'hi') {
      return '${catalog.nameHi}। यह कलाकृति पूरी तरह से हाथ से तैयार की गई है। '
          'सामग्री: ${catalog.materialHi}। '
          'यह शत-प्रतिशत पर्यावरण अनुकूल है। ग्रामीण कारीगरों के सशक्तिकरण के लिए सीधी खरीद।';
    }
    return '${catalog.nameEn}. Skillfully handcrafted by traditional artisans using certified ${catalog.materialEn}. '
        '100% eco-friendly and culturally authentic. Directly supports generational craft livelihoods.';
  }

  /// Plain, simple spoken sentence designed for Text-to-Speech audio playback
  /// so an illiterate artisan instantly knows what the camera captured.
  String _spokenInsight(_CatalogRule catalog, List<String> tags, String languageCode) {
    if (languageCode == 'hi') {
      return 'AI ने आपकी तस्वीर में "${catalog.nameHi}" पहचाना है। इसका उचित मूल्य ₹${catalog.low} से ₹${catalog.high} तक हो सकता है। आप माइक दबाकर कुछ भी बोल सकते हैं।';
    }
    return 'AI detected "${catalog.nameEn}" from your photo. Fair price range is ₹${catalog.low} to ₹${catalog.high}. You can speak to adjust any detail.';
  }
}

class _CatalogRule {
  const _CatalogRule({
    required this.nameEn,
    required this.nameHi,
    required this.category,
    required this.materialEn,
    required this.materialHi,
    required this.low,
    required this.high,
  });

  final String nameEn;
  final String nameHi;
  final String category;
  final String materialEn;
  final String materialHi;
  final int low;
  final int high;

  String name(String languageCode) => languageCode == 'hi' ? nameHi : nameEn;
  int get suggested => ((low + high) / 2).round();
}
