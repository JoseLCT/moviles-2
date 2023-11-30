import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace/models/product_model.dart';

final String url = dotenv.get('API_URL');

Future<List<Product>> getProducts() async {
  final response = await http.get(Uri.parse('$url/api/products'));

  if (response.statusCode == 200) {
    final List<Product> products = productListFromJson(response.body);
    return products;
  } else {
    throw Exception('Failed to load products');
  }
}

Future<Product?> getProduct(int id) async {
  final response = await http.get(Uri.parse('$url/api/products/$id'));

  if (response.statusCode == 200) {
    final Product product = productFromJson(response.body);
    return product;
  } else if (response.statusCode == 404) {
    return null;
  } else {
    throw Exception('Failed to load product');
  }
}

Future<List<Product>> getProductsByCategory(int id) async {
  final response = await http.get(Uri.parse('$url/api/products/category/$id'));

  if (response.statusCode == 200) {
    final List<Product> products = productListFromJson(response.body);
    return products;
  } else {
    throw Exception('Failed to load products');
  }
}

Future<List<Product>> searchProductsByLocation(
    LatLng location, double radius) async {
  final response =
      await http.post(Uri.parse('$url/api/products/search'), body: {
    'latitude': location.latitude.toString(),
    'longitude': location.longitude.toString(),
    'radius_km': radius.toString()
  });
  if (response.statusCode == 200) {
    final List<Product> products = productListFromJson(response.body);
    return products;
  } else {
    throw Exception('Failed to load products');
  }
}

Future<List<Product>> getProductsByToken(String token) async {
  final response = await http.get(Uri.parse('$url/api/products'), headers: {
    'Authorization': 'Bearer $token',
  });

  if (response.statusCode == 200) {
    final List<Product> products = productListFromJson(response.body);
    return products;
  } else {
    throw Exception('Error al obtener productos');
  }
}

Future<Product> insertProduct(Product product, String token) async {
  final response = await http.post(
    Uri.parse('$url/api/products'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: productToJson(product),
  );

  if (response.statusCode == 200) {
    final Product productResponse = productFromJson(response.body);
    return productResponse;
  } else {
    throw Exception(response.body);
  }
}

Future<bool> insertImage(int productId, String path, String token) async {
  var request = http.MultipartRequest(
      "POST", Uri.parse('$url/api/products/$productId/image'));
  request.files.add(await http.MultipartFile.fromPath('image', path));
  request.headers.addAll({'Authorization': 'Bearer $token'});
  final response = await request.send();

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception(response.reasonPhrase);
  }
}

Future<bool> deleteImage(int imgId, String token) async {
  final response = await http.delete(
    Uri.parse('$url/api/products/image/$imgId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception(response.body);
  }

}

Future<bool> updateProduct(Product product, String token, int id) async {
  final response = await http.put(
    Uri.parse('$url/api/products/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: productToJson(product),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception(response.body);
  }
}
