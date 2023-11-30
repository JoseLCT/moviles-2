import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  int? id;
  String? fullname;
  String? email;
  String? password;

  User({
    this.id,
    this.fullname,
    this.email,
    this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"] ?? 0,
        fullname: json["fullname"] ?? '',
        email: json["email"] ?? '',
        password: json["password"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "id": id ?? 0,
        "fullname": fullname,
        "email": email,
        "password": password,
      };
}
