class User {
  final String id;
  final String username;
  final String role;
  final String token;

  const User({
    required this.id,
    required this.username,
    required this.role,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['userId'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'username': username,
      'role': role,
    };
  }
}
