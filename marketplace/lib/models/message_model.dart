import 'dart:convert';
import 'dart:io';

import 'package:marketplace/models/user_model.dart';

List<Message> messageListFromJson(String str) =>
    List<Message>.from(json.decode(str).map((x) => Message.fromJson(x)));

String messageListToJson(List<Message> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Message {
  String? imageUrl;
  int? id;
  int? chatId;
  int? type;
  String? message;
  String? latitude;
  String? longitude;
  String? imageExtension;
  int? userIdSender;
  int? userIdReceiver;
  DateTime? createdAt;
  DateTime? updatedAt;
  User? userSender;
  User? userReceiver;

  Message({
    this.imageUrl,
    this.id,
    this.chatId,
    this.type,
    this.message,
    this.latitude,
    this.longitude,
    this.imageExtension,
    this.userIdSender,
    this.userIdReceiver,
    this.createdAt,
    this.updatedAt,
    this.userSender,
    this.userReceiver,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        imageUrl: json["image_url"],
        id: json["id"],
        chatId: json["chat_id"],
        type: json["type"],
        message: json["message"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        imageExtension: json["image_extension"],
        userIdSender: json["user_id_sender"],
        userIdReceiver: json["user_id_receiver"],
        createdAt: json["createdAt"] != null
            ? DateTime.parse(json["createdAt"])
            : null,
        updatedAt: json["updatedAt"] != null
            ? DateTime.parse(json["updatedAt"])
            : null,
        userSender: json["user_sender"] != null
            ? User.fromJson(json["user_sender"])
            : null,
        userReceiver: json["user_receiver"] != null
            ? User.fromJson(json["user_receiver"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "image_url": imageUrl,
        "id": id,
        "chat_id": chatId,
        "type": type,
        "message": message,
        "latitude": latitude,
        "longitude": longitude,
        "image_extension": imageExtension,
        "user_id_sender": userIdSender,
        "user_id_receiver": userIdReceiver,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}
