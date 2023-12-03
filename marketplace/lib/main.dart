import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:marketplace/pages/auth/login_page.dart';
import 'package:marketplace/pages/auth/register_page.dart';
import 'package:marketplace/pages/chat_page.dart';
import 'package:marketplace/pages/home_page.dart';
import 'package:marketplace/pages/maps_page.dart';
import 'package:marketplace/pages/product_detail_page.dart';
import 'package:marketplace/pages/product_form_page.dart';
import 'package:marketplace/pages/profile_page.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey.shade900),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/product-detail': (context) => const ProductDetailPage(),
        '/product-form': (context) => const ProductFormPage(),
        '/maps': (context) => const MapsPage(),
        '/profile': (context) => const ProfilePage(),
        '/chat': (context) => const ChatPage(),
      },
    );
  }
}
