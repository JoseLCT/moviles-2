import 'package:flutter_dotenv/flutter_dotenv.dart';
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

Future<Product> getProduct(int id) async {
  final response = await http.get(Uri.parse('$url/api/products/$id'));

  if (response.statusCode == 200) {
    final Product product = productFromJson(response.body);
    return product;
  } else {
    throw Exception('Failed to load product');
  }
}