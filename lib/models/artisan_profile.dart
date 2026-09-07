class ArtisanProfile {
  const ArtisanProfile({
    required this.name,
    required this.location,
    required this.languageCode,
    this.craftCategory = 'Traditional Indian Handicrafts',
    this.villageOrCity,
    this.phone,
    this.bio,
    this.isArtisan = false,
  });

  final String name;
  final String location;
  final String languageCode;
  final String craftCategory;
  final String? villageOrCity;
  final String? phone;
  final String? bio;
  final bool isArtisan;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'location': location,
        'languageCode': languageCode,
        'craftCategory': craftCategory,
        'villageOrCity': villageOrCity,
        'phone': phone,
        'bio': bio,
        'isArtisan': isArtisan,
      };

  factory ArtisanProfile.fromJson(Map<String, dynamic> json) => ArtisanProfile(
        name: json['name'] as String? ?? 'User',
        location: json['location'] as String? ?? 'India',
        languageCode: json['languageCode'] as String? ?? 'en',
        craftCategory: json['craftCategory'] as String? ?? 'Traditional Indian Handicrafts',
        villageOrCity: json['villageOrCity'] as String?,
        phone: json['phone'] as String?,
        bio: json['bio'] as String?,
        isArtisan: json['isArtisan'] as bool? ?? false,
      );

  ArtisanProfile copyWith({
    String? name,
    String? location,
    String? languageCode,
    String? craftCategory,
    String? villageOrCity,
    String? phone,
    String? bio,
    bool? isArtisan,
  }) =>
      ArtisanProfile(
        name: name ?? this.name,
        location: location ?? this.location,
        languageCode: languageCode ?? this.languageCode,
        craftCategory: craftCategory ?? this.craftCategory,
        villageOrCity: villageOrCity ?? this.villageOrCity,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
        isArtisan: isArtisan ?? this.isArtisan,
      );
}
