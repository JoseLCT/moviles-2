import 'dart:convert';

List<Category> categoryListFromJson(String str) => List<Category>.from(json.decode(str).map((x) => Category.fromJson(x)));
String categoryListToJson(List<Category> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

Category categoryFromJson(String str) => Category.fromJson(json.decode(str));
String categoryToJson(Category data) => json.encode(data.toJson());

class Category {
    int? id;
    String? name;

    Category({
        this.id,
        this.name,
    });

    factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"] ?? 0,
        name: json["name"] ?? '',
    );

    Map<String, dynamic> toJson() => {
        "id": id ?? 0,
        "name": name ?? '',
    };
}