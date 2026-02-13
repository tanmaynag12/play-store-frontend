class AppModel {
  final int id;
  final String name;
  final String description;
  final String iconUrl;
  final String? version;
  final String? size;
  final String? developer;

  AppModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.version,
    this.size,
    this.developer,
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
    );
  }
}
