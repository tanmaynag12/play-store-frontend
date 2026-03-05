class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? profileImage;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      profileImage: json['profile_image'],
    );
  }

  bool get isAdmin => role == 'admin';
}
