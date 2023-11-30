import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace/models/user_model.dart';

final String url = dotenv.get('API_URL');

Future<String> login(String email, String password) async {
  final response = await http.post(Uri.parse('$url/api/auth/loginuser'), body: {
    'email': email,
    'password': password,
  });

  if (response.statusCode == 200) {
    return response.body;
  }
  switch (response.statusCode) {
    case 401:
      throw Exception('Correo o contraseña incorrectos');
    default:
      throw Exception('Error al iniciar sesión');
  }
}

Future<User> register(String fullname, String email, String password) async {
  final response =
      await http.post(Uri.parse('$url/api/auth/registeruser'), body: {
    'fullname': fullname,
    'email': email,
    'password': password,
  });

  if (response.statusCode == 201) {
    final User user = userFromJson(response.body);
    return user;
  } else if (response.statusCode == 400) {
    throw Exception('El correo ya se encuentra registrado');
  } else {
    throw Exception('Error al registrar usuario');
  }
}

Future<User> getUser(String token) async {
  final response = await http.get(Uri.parse('$url/api/auth/me'), headers: {
    'Authorization': 'Bearer $token',
  });

  if (response.statusCode == 200) {
    final User user = userFromJson(response.body);
    return user;
  } else if (response.statusCode == 401) {
    throw Exception('401');
  } else {
    throw Exception('Error al obtener usuario');
  }
}
