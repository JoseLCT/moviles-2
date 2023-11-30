import 'package:flutter/material.dart';
import 'package:marketplace/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _showPassword = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade900,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        body: SafeArea(
            child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                child: Column(children: [
                  const Text('Regístrate',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  getForm(),
                ]))));
  }

  Widget getForm() {
    return Expanded(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _fullnameController,
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu nombre completo';
                }
                return null;
              },
              decoration: InputDecoration(
                  label: const Text('Nombre completo'),
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  floatingLabelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 43, 43, 43),
                  errorStyle: const TextStyle(color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey.shade600)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white70)),
                  errorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.red)),
                  focusedErrorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.red))),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu correo electrónico';
                }
                if (!RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
                    .hasMatch(value)) {
                  return 'Por favor ingresa un correo electrónico válido';
                }
                return null;
              },
              decoration: InputDecoration(
                  label: const Text('Correo electrónico'),
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  floatingLabelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 43, 43, 43),
                  errorStyle: const TextStyle(color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey.shade600)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white70)),
                  errorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.red)),
                  focusedErrorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.red))),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: _showPassword,
              enableSuggestions: false,
              autocorrect: false,
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu contraseña';
                }
                if (value.length < 8) {
                  return 'La contraseña debe tener al menos 8 caracteres';
                }
                if (value.contains(' ')) {
                  return 'La contraseña no debe contener espacios';
                }
                return null;
              },
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                    icon: Icon(
                        _showPassword == true
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey),
                  ),
                  label: const Text('Contraseña'),
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  floatingLabelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 43, 43, 43),
                  errorStyle: const TextStyle(color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey.shade600)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white70)),
                  errorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.red)),
                  focusedErrorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.red))),
            ),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      register(
                              _fullnameController.text.trim(),
                              _emailController.text.trim(),
                              _passwordController.text.trim())
                          .then((value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Registro exitoso, por favor inicia sesión'),
                                backgroundColor:
                                    Color.fromARGB(255, 18, 87, 189)));
                        Navigator.of(context).pop();
                      }).catchError((error) {
                        String errorMessage =
                            error.toString().split(':')[1].trim();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red));
                      });
                    }
                  },
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          const Color.fromARGB(255, 18, 87, 189)),
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 12))),
                  child: const Text('Registrarse',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                )),
          ],
        ),
      ),
    );
  }
}
