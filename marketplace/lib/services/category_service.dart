import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace/models/category_model.dart';

final String url = dotenv.get('API_URL');

Future<List<Category>> getCategories() async {
  final response = await http.get(Uri.parse('$url/api/categories'));

  if (response.statusCode == 200) {
    final List<Category> categories = categoryListFromJson(response.body);
    return categories;
  } else {
    throw Exception('Failed to load categories');
  }
}