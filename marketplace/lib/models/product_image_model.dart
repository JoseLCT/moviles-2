import 'dart:convert';

List<ProductImage> productImageListFromJson(String str) => List<ProductImage>.from(json.decode(str).map((x) => ProductImage.fromJson(x)));
String productImageListToJson(List<ProductImage> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

ProductImage productImageFromJson(String str) => ProductImage.fromJson(json.decode(str));
String productImageToJson(ProductImage data) => json.encode(data.toJson());

class ProductImage {
    String url;
    int id;
    int productId;
    String extension;

    ProductImage({
        required this.url,
        required this.id,
        required this.productId,
        required this.extension,
    });

    factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        url: json["url"],
        id: json["id"],
        productId: json["product_id"],
        extension: json["extension"],
    );

    Map<String, dynamic> toJson() => {
        "url": url,
        "id": id,
        "product_id": productId,
        "extension": extension,
    };
}