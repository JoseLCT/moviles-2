import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marketplace/models/category_model.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/services/category_service.dart';
import 'package:marketplace/services/product_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiUrl = dotenv.get('API_URL');
  Future<List<Category>>? categories;
  int? _idCategory = 0;

  final Completer<GoogleMapController> _mapsController = Completer();

  @override
  void initState() {
    super.initState();
    categories = getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey.shade900,
      body: CustomScrollView(
        slivers: [getHeader(), getSubHeader(), getProductListView()],
      ),
    );
  }

  Widget getHeader() {
    return SliverAppBar(
      title: const Text('Marketplace', style: TextStyle(color: Colors.white)),
      floating: false,
      snap: false,
      pinned: true,
      backgroundColor: Colors.grey.shade900,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                  const Color.fromARGB(255, 54, 54, 54))),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                  const Color.fromARGB(255, 54, 54, 54))),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget getSubHeader() {
    return SliverToBoxAdapter(
        child: Row(
      children: [
        TextButton(
            onPressed: () {},
            child: const Text('Vender',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16))),
        const SizedBox(width: 8),
        const Text('|', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        IconButton(
            onPressed: () {
              showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  backgroundColor: Colors.grey.shade900,
                  barrierColor: Colors.black.withOpacity(0.5),
                  builder: (context) {
                    return getCategoryFilterView();
                  });
            },
            icon: const Icon(Icons.filter_list, color: Colors.white)),
        IconButton(
            onPressed: () {},
            icon: const Icon(Icons.location_on, color: Colors.white)),
      ],
    ));
  }

  Widget getCategoryFilterView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Categorias',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          FutureBuilder(
              future: categories,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return StatefulBuilder(
                      builder: (context, setStateBottomSheet) {
                    return getCategoryListView(
                        snapshot.data, setStateBottomSheet);
                  });
                } else if (snapshot.hasError) {
                  return const Text('Error');
                } else {
                  return const CircularProgressIndicator();
                }
              }),
        ],
      ),
    );
  }

  Widget getCategoryListView(
      List<Category>? categories, Function setStateBottomSheet) {
    if (categories == null) {
      return const Text('Error');
    }
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: List<Widget>.generate(categories.length, (index) {
        return ChoiceChip(
          label: Text(categories[index].name,
              style: const TextStyle(color: Colors.white)),
          selected: _idCategory == categories[index].id,
          selectedColor: const Color.fromARGB(255, 0, 122, 255),
          backgroundColor: const Color.fromARGB(255, 54, 54, 54),
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide.none,
          onSelected: (selected) {
            setStateBottomSheet(() {
              _idCategory = selected ? categories[index].id : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget getMap() {
    return Container(
      height: 200,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: const CameraPosition(
          target: LatLng(-17.7833, -63.1667),
          zoom: 14,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapsController.complete(controller);
        },
      ),
    );
  }

  Widget getProductListView() {
    return FutureBuilder<List<Product>>(
      future: getProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                return getProductView(snapshot.data?[index]);
              }, childCount: snapshot.data?.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 4, mainAxisSpacing: 8));
        } else if (snapshot.hasError) {
          return const SliverToBoxAdapter(child: Text('Error'));
        } else {
          return const SliverToBoxAdapter(child: Text('Loading... '));
        }
      },
    );
  }

  Widget getProductView(Product? product) {
    if (product == null || product.id == 1) {
      return const Text('Error');
    }
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-detail',
            arguments: {'id': product.id});
      },
      child: Column(
        children: [
          if (product.productimages.isNotEmpty)
            Image.network(apiUrl + product.productimages[0].url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: (MediaQuery.of(context).size.width / 2) - 24,
                loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(),
              );
            }),
          Row(
            children: [
              Text(
                  product.price == 0
                      ? 'Gratis ·'
                      : 'Bs. ${product.price.toString()} ·',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(width: 5),
              Expanded(
                  child: Text(product.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }
}
