class User {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? image;
  final String? gender; // Adicionado

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.image,
    this.gender,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      image: json['image'] as String?,
      gender: json['gender'] as String?, // Adicionado
    );
  }
}
