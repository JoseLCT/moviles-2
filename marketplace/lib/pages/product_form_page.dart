import 'package:flutter/material.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Nueva publicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          TextButton(
              onPressed: () {},
              child: const Text('Publicar',
                  style: TextStyle(color: Color.fromARGB(255, 0, 122, 255), fontSize: 16))),
        ],
        backgroundColor: Colors.grey.shade900,
      ),
      body: Container(),
    );
  }
}
