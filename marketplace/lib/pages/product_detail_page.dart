import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/services/product_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final String apiUrl = dotenv.get('API_URL');
  final String mapsApiKey = dotenv.get('GOOGLE_MAPS_API_KEY');
  final _formKey = GlobalKey<FormState>();
  final double _margin = 10.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      extendBody: true,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {},
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: FutureBuilder(
          future: getProduct(6),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return getProductView(snapshot.data);
            } else if (snapshot.hasError) {
              return const Text('Error');
            } else {
              return const Text('Loading...');
            }
          }),
    );
  }

  Widget getProductView(Product? product) {
    if (product == null) {
      return const Text('No product found');
    }
    return SingleChildScrollView(
        child: Column(
      children: [
        CarouselSlider(
            items: product.productimages.map((img) {
              return Image.network(apiUrl + img.url,
                  width: double.infinity, fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(),
                );
              });
            }).toList(),
            options: CarouselOptions(
              viewportFraction: 1,
              aspectRatio: 1,
              enableInfiniteScroll: false,
            )),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: _margin, top: _margin),
            child: Text(
              product.name,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: _margin),
            child: Text(
              product.price == 0 ? 'Gratis' : 'Bs. ${product.price}',
              style: const TextStyle(
                  fontSize: 20, color: Color.fromARGB(255, 228, 230, 235)),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.all(_margin),
          width: double.infinity,
          child: Card(
              color: Colors.grey.shade800,
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.question_answer_rounded,
                              color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Envía un mensaje al vendedor',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Form(
                        key: _formKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    'Hola, sigue disponible el producto?',
                                decoration: InputDecoration(
                                  hintText: 'Escribe tu mensaje...',
                                  hintStyle: const TextStyle(
                                      color:
                                          Color.fromARGB(255, 228, 230, 235)),
                                  filled: true,
                                  fillColor: Colors.grey.shade700,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  isDense: true,
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(25.0),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 228, 230, 235),
                                    fontSize: 16),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor escribe un mensaje';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 122, 255),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Sending message')));
                                }
                              },
                              child: const Text('Enviar',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            )
                          ],
                        ),
                      )
                    ],
                  ))),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: _margin, top: _margin),
            child: const Text(
              'Descripción',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: _margin),
            child: Text(
              product.description,
              style: const TextStyle(
                  fontSize: 16, color: Color.fromARGB(255, 228, 230, 235)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
            margin: EdgeInsets.only(
                left: _margin, top: _margin, right: _margin, bottom: 16),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: GestureDetector(
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Abriendo Google Maps...')));
                        Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${product.latitude},${product.longitude}');
                        if (await canLaunchUrl(url)) {
                          launchUrl(url);
                        }
                  },
                  child: Image.network(
                      'https://maps.googleapis.com/maps/api/staticmap?center=${product.latitude},${product.longitude}&zoom=14&size=900x400&key=$mapsApiKey',
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }),
                )))
      ],
    ));
  }
}