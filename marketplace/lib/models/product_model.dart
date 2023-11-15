import 'dart:convert';

import 'package:marketplace/models/category_model.dart';
import 'package:marketplace/models/product_image_model.dart';

List<Product> productListFromJson(String str) => List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));
String productListToJson(List<Product> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

Product productFromJson(String str) => Product.fromJson(json.decode(str));
String productToJson(Product data) => json.encode(data.toJson());

class Product {
    int? id;
    String name;
    String description;
    int price;
    String latitude;
    String longitude;
    int categoryId;
    int status;
    int sold;
    int userId;
    List<ProductImage> productimages;
    Category category;

    Product({
        this.id,
        required this.name,
        required this.description,
        required this.price,
        required this.latitude,
        required this.longitude,
        required this.categoryId,
        required this.status,
        required this.sold,
        required this.userId,
        required this.productimages,
        required this.category,
    });

    factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        price: json["price"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        categoryId: json["category_id"],
        status: json["status"],
        sold: json["sold"],
        userId: json["user_id"],
        productimages: List<ProductImage>.from(json["productimages"].map((x) => ProductImage.fromJson(x))),
        category: Category.fromJson(json["category"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "price": price,
        "latitude": latitude,
        "longitude": longitude,
        "category_id": categoryId,
        "status": status,
        "sold": sold,
        "user_id": userId,
        "productimages": List<dynamic>.from(productimages.map((x) => x.toJson())),
        "category": category.toJson(),
    };
}

