class User {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? image;
  final int age;
  final String gender;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.image,
    required this.age,
    required this.gender,
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
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? '',
    );
  }
}
