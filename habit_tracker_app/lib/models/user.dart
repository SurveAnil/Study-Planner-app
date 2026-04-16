class User {
  final int id;
  final String name;
  final String email;
  final String firebaseUid;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.firebaseUid,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      firebaseUid: json['firebase_uid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'firebase_uid': firebaseUid,
    };
  }
}
