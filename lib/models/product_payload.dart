/// The single structured contract emitted by the edge pipeline / cloud
/// enrichment service. Every product template is hydrated from this payload.
class ProductPayload {
  const ProductPayload({
    required this.id,
    required this.heroImagePath,
    required this.name,
    required this.category,
    required this.description,
    required this.suggestedPrice,
    required this.priceLow,
    required this.priceHigh,
    required this.currency,
    required this.tags,
    required this.moreInfo,
    required this.additionalImages,
    required this.comments,
    this.artisanId = 'artisan-default',
    this.artisanName = 'Traditional Indian Artisan',
    this.artisanLocation = 'India',
    this.rating = 4.8,
    this.reviewCount = 24,
    this.mrp,
    this.discountPercent = 25,
    this.material = 'Natural handcrafted materials',
    this.cleanHeroImagePath,
    this.isFeatured = false,
  });

  final String id;
  final String heroImagePath;
  final String name;
  final String category;
  final String description;
  final int suggestedPrice;
  final int priceLow;
  final int priceHigh;
  final String currency;
  final List<String> tags;
  final String moreInfo;
  final List<String> additionalImages;
  final List<NativeComment> comments;
  final String artisanId;
  final String artisanName;
  final String artisanLocation;
  final double rating;
  final int reviewCount;
  final int? mrp;
  final int discountPercent;
  final String material;
  final String? cleanHeroImagePath;
  final bool isFeatured;

  int get effectiveMrp => mrp ?? (suggestedPrice * 1.35).round();

  factory ProductPayload.fromJson(Map<String, dynamic> json) {
    final suggested = (json['suggestedPrice'] as num).round();
    return ProductPayload(
      id: json['id'] as String,
      heroImagePath: json['heroImagePath'] as String,
      name: json['name'] as String? ?? 'Handcrafted item',
      category: json['category'] as String? ?? 'Handicrafts',
      description: json['description'] as String,
      suggestedPrice: suggested,
      priceLow: ((json['priceLow'] ?? json['suggestedPrice']) as num).round(),
      priceHigh: ((json['priceHigh'] ?? json['suggestedPrice']) as num).round(),
      currency: json['currency'] as String? ?? 'INR',
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? const <String>[]),
      moreInfo: json['moreInfo'] as String? ?? '',
      additionalImages: List<String>.from(json['additionalImages'] as List<dynamic>? ?? const <String>[]),
      comments: (json['comments'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => NativeComment.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      artisanId: json['artisanId'] as String? ?? 'artisan-default',
      artisanName: json['artisanName'] as String? ?? 'Traditional Indian Artisan',
      artisanLocation: json['artisanLocation'] as String? ?? 'India',
      rating: ((json['rating'] ?? 4.8) as num).toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.round() ?? 24,
      mrp: (json['mrp'] as num?)?.round(),
      discountPercent: (json['discountPercent'] as num?)?.round() ?? 25,
      material: json['material'] as String? ?? 'Natural handcrafted materials',
      cleanHeroImagePath: json['cleanHeroImagePath'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'heroImagePath': heroImagePath,
        'name': name,
        'category': category,
        'description': description,
        'suggestedPrice': suggestedPrice,
        'priceLow': priceLow,
        'priceHigh': priceHigh,
        'currency': currency,
        'tags': tags,
        'moreInfo': moreInfo,
        'additionalImages': additionalImages,
        'artisanId': artisanId,
        'artisanName': artisanName,
        'artisanLocation': artisanLocation,
        'rating': rating,
        'reviewCount': reviewCount,
        'mrp': mrp,
        'discountPercent': discountPercent,
        'material': material,
        'cleanHeroImagePath': cleanHeroImagePath,
        'isFeatured': isFeatured,
        'comments': comments
            .map((comment) => <String, Object?>{
                  'author': comment.author,
                  'message': comment.message,
                  'languageCode': comment.languageCode,
                })
            .toList(growable: false),
      };

  ProductPayload copyWith({
    int? suggestedPrice,
    int? priceLow,
    int? priceHigh,
    List<NativeComment>? comments,
    String? heroImagePath,
    List<String>? additionalImages,
    String? moreInfo,
    String? name,
    String? category,
    String? description,
    String? artisanId,
    String? artisanName,
    String? artisanLocation,
    double? rating,
    int? reviewCount,
    int? mrp,
    int? discountPercent,
    String? material,
    String? cleanHeroImagePath,
    bool? isFeatured,
    List<String>? tags,
  }) =>
      ProductPayload(
        id: id,
        heroImagePath: heroImagePath ?? this.heroImagePath,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        suggestedPrice: suggestedPrice ?? this.suggestedPrice,
        priceLow: priceLow ?? this.priceLow,
        priceHigh: priceHigh ?? this.priceHigh,
        currency: currency,
        tags: tags ?? this.tags,
        moreInfo: moreInfo ?? this.moreInfo,
        additionalImages: additionalImages ?? this.additionalImages,
        comments: comments ?? this.comments,
        artisanId: artisanId ?? this.artisanId,
        artisanName: artisanName ?? this.artisanName,
        artisanLocation: artisanLocation ?? this.artisanLocation,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        mrp: mrp ?? this.mrp,
        discountPercent: discountPercent ?? this.discountPercent,
        material: material ?? this.material,
        cleanHeroImagePath: cleanHeroImagePath ?? this.cleanHeroImagePath,
        isFeatured: isFeatured ?? this.isFeatured,
      );
}

class NativeComment {
  const NativeComment({required this.author, required this.message, required this.languageCode});

  final String author;
  final String message;
  final String languageCode;

  factory NativeComment.fromJson(Map<String, dynamic> json) => NativeComment(
        author: json['author'] as String? ?? 'Buyer',
        message: json['message'] as String,
        languageCode: json['languageCode'] as String? ?? 'hi',
      );
}
