import 'dart:convert';

import 'package:marketplace/models/message_model.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/models/user_model.dart';

List<Chat> chatListFromJson(String str) =>
    List<Chat>.from(json.decode(str).map((x) => Chat.fromJson(x)));

String chatListToJson(List<Chat> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

Chat chatFromJson(String str) => Chat.fromJson(json.decode(str));

String chatToJson(Chat data) => json.encode(data.toJson());

class Chat {
  int? id;
  int? userId;
  int? productId;
  DateTime? createdAt;
  DateTime? updatedAt;
  Product? product;
  User? user;
  Message? lastMessage;

  Chat({
    this.id,
    this.userId,
    this.productId,
    this.createdAt,
    this.updatedAt,
    this.product,
    this.user,
    this.lastMessage,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json["id"] ?? 0,
        userId: json["user_id"] ?? 0,
        productId: json["product_id"] ?? 0,
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        product: Product.fromJson(json["product"]),
        user: User.fromJson(json["user"]),
        lastMessage: Message.fromJson(json["lastMessage"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "product_id": productId,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "product": product?.toJson(),
        "user": user?.toJson(),
        "lastMessage": lastMessage?.toJson(),
      };
}
