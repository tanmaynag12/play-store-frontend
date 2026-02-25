class AppModel {
  final int id;
  final String name;
  final String description;
  final String iconUrl;
  final String? version;
  final String? size;
  final String? developer;
  final double? averageRating;
  final int totalReviews;

  AppModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.version,
    this.size,
    this.developer,
    this.averageRating,
    this.totalReviews = 0,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? "",
      iconUrl: json['icon_url'],
      version: json['version'],
      size: json['size'],
      developer: json['developer'],
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
      totalReviews: json['total_reviews'] ?? 0,
    );
  }
}
