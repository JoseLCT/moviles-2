import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:marketplace/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _hidePassword = true;
  final LocalStorage storage = LocalStorage('marketplace_app');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
      ),
      body: SafeArea(
          child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Column(
                children: [
                  const Text('Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  getForm(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes una cuenta?',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Regístrate',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      )
                    ],
                  )
                ],
              ))),
    );
  }

  Widget getForm() {
    return Expanded(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                label: const Text('Correo electrónico'),
                labelStyle: TextStyle(color: Colors.grey.shade600),
                floatingLabelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color.fromARGB(255, 43, 43, 43),
                enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.grey.shade600)),
                focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              enableSuggestions: false,
              autocorrect: false,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },
                  icon: Icon(
                      _hidePassword == true
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey),
                ),
                label: const Text('Contraseña'),
                labelStyle: TextStyle(color: Colors.grey.shade600),
                floatingLabelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color.fromARGB(255, 43, 43, 43),
                enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.grey.shade600)),
                focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    if (_emailController.text.isEmpty ||
                        _passwordController.text.isEmpty) {
                      showScaffoldMessage(
                          'Por favor ingresa tu correo y contraseña', null);
                      return;
                    }
                    login(_emailController.text, _passwordController.text)
                        .then((value) {
                      showScaffoldMessage('Inicio de sesión exitoso',
                          const Color.fromARGB(255, 18, 87, 189));
                      storage.setItem('token', jsonDecode(value)['access_token']);
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/', (route) => false);
                    }).catchError((error) {
                      String errorMessage =
                          error.toString().split(':')[1].trim();
                      showScaffoldMessage(errorMessage, Colors.red);
                    });
                  },
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          const Color.fromARGB(255, 18, 87, 189)),
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 12))),
                  child: const Text('Iniciar sesión',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                )),
          ],
        ),
      ),
    );
  }

  void showScaffoldMessage(String message, Color? bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: bg,
        content: Text(message, style: const TextStyle(color: Colors.white))));
  }
}
