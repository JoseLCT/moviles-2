import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:localstorage/localstorage.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/services/product_service.dart';
import 'package:shimmer/shimmer.dart';
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
  final LocalStorage storage = LocalStorage('marketplace_app');

  @override
  Widget build(BuildContext context) {
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    final int id = arguments['id'];

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
        backgroundColor: Colors.grey.shade900,
      ),
      body: FutureBuilder(
          future: getProduct(id),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return getProductView(snapshot.data);
            } else if (snapshot.hasError) {
              return const Text('Error');
            } else {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
          }),
    );
  }

  Widget getProductView(Product? product) {
    if (product == null) {
      return const Text('No product found');
    }
    String token = storage.getItem('token') ?? '';
    return SingleChildScrollView(
        child: Column(
      children: [
        if (product.productimages != null &&
            product.productimages!.isNotEmpty) ...[
          getSlider(product),
        ] else ...[
          Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey,
            child: const Center(
              child: Icon(Icons.image, color: Colors.white, size: 100),
            ),
          )
        ],
        Container(
          margin:
              const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              product.name,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Text(
              product.price == 0 ? 'Gratis' : 'Bs. ${product.price}',
              style: const TextStyle(
                  fontSize: 18, color: Color.fromARGB(255, 228, 230, 235)),
            ),
            if (token.isNotEmpty) ...[
              getCardMessage(),
            ] else ...[
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade700),
              const SizedBox(height: 8),
            ],
            const Text(
              'Descripción',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: const TextStyle(
                  fontSize: 16, color: Color.fromARGB(255, 228, 230, 235)),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade700),
            if (token.isNotEmpty)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                const Text('Información del vendedor',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      product.user?.fullname ?? 'N/A',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 228, 230, 235)),
                    ),
                    const Spacer(),
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: const Color.fromARGB(255, 54, 54, 54),
                      ),
                      child: const Icon(Icons.message,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade700),
              ]),
            const SizedBox(height: 8),
            const Text(
              'Detalles',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    'Estado',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ),
                Text(
                  product.status == 1 ? 'Nuevo' : 'Usado',
                  style: const TextStyle(
                      fontSize: 16, color: Color.fromARGB(255, 228, 230, 235)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    'Categoría',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ),
                Text(
                  product.category?.name ?? 'N/A',
                  style: const TextStyle(
                      fontSize: 16, color: Color.fromARGB(255, 228, 230, 235)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade700),
            const SizedBox(height: 16),
            if (token.isNotEmpty) ...[
              getMapCard(product),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Inicia sesión para contactar al vendedor',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 228, 230, 235)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            )),
                            backgroundColor: MaterialStateProperty.all(
                                const Color.fromARGB(255, 18, 87, 189)),
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 10))),
                        child: const Text('Iniciar sesión',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      )),
                ],
              )
            ],
            const SizedBox(height: 8),
          ]),
        )
      ],
    ));
  }

  Widget getSlider(Product product) {
    return CarouselSlider(
        items: product.productimages?.map((img) {
          return GestureDetector(
            onTap: () {
              _showFullScreenImage(apiUrl + img.url);
            },
            child: Image.network(apiUrl + img.url,
                width: double.infinity, fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Shimmer.fromColors(
                  baseColor: Colors.grey.shade800,
                  highlightColor: Colors.grey.shade700,
                  child: Container(color: Colors.grey));
            }),
          );
        }).toList(),
        options: CarouselOptions(
          viewportFraction: 1,
          aspectRatio: 1,
          enableInfiniteScroll: false,
        ));
  }

  void _showFullScreenImage(String path) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: SizedBox.expand(
            child: Image.network(
              path,
              width: MediaQuery.of(context).size.width,
            ),
          ),
        );
      },
    );
  }

  Widget getCardMessage() {
    return Card(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        color: Colors.grey.shade800,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.question_answer_rounded, color: Colors.green),
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
                          initialValue: 'Hola, sigue disponible el producto?',
                          decoration: InputDecoration(
                            hintText: 'Escribe tu mensaje...',
                            hintStyle: const TextStyle(
                                color: Color.fromARGB(255, 228, 230, 235)),
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
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      )
                    ],
                  ),
                )
              ],
            )));
  }

  Widget getMapCard(Product product) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: GestureDetector(
          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abriendo Google Maps...')));
            Uri url = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${product.latitude},${product.longitude}');
            if (await canLaunchUrl(url)) {
              launchUrl(url);
            }
          },
          child: Image.network(
              'https://maps.googleapis.com/maps/api/staticmap?center=${product.latitude},${product.longitude}&markers=size:mid%7Ccolor:red%7C${product.latitude},${product.longitude}&zoom=14&size=900x400&key=$mapsApiKey',
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
        ));
  }
}
