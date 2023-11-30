import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:marketplace/models/category_model.dart';
import 'package:marketplace/models/map_data_model.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/services/category_service.dart';
import 'package:marketplace/services/product_service.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiUrl = dotenv.get('API_URL');
  final LocalStorage storage = LocalStorage('marketplace_app');
  Future<List<Category>>? categories;
  Future<List<Product>>? products;
  Future<List<Product>>? productsFiltered;
  int? _idCategory;
  LatLng _currentPosition = const LatLng(-17.7837702, -63.18416);
  double _radius = 1.5;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    categories = getCategories();
    getStoredData();
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

  void getStoredData() {
    if (storage.getItem('currentLocation') != null) {
      MapData mapData = mapDataFromJson(storage.getItem('currentLocation'));
      setState(() {
        _radius = mapData.radius ?? 1.5;
        _currentPosition = LatLng(double.parse(mapData.latitude),
            double.parse(mapData.longitude));
        products = searchProductsByLocation(_currentPosition, _radius);
        if (_idCategory == null) {
          productsFiltered = products;
        } else {
          productsFiltered = products?.then((value) =>
              value.where((item) => item.categoryId == _idCategory).toList());
        }
      });
    } else {
      _determinePosition().then((value) {
        _currentPosition = value;
        MapData mapData = MapData(
            latitude: _currentPosition.latitude.toString(),
            longitude: _currentPosition.longitude.toString(),
            radius: _radius);
        storage.setItem('currentLocation', mapDataToJson(mapData));
        setState(() {
          products = searchProductsByLocation(_currentPosition, _radius);
          if (_idCategory == null) {
            productsFiltered = products;
          } else {
            productsFiltered = products?.then((value) =>
                value.where((item) => item.categoryId == _idCategory).toList());
          }
        });
      });
    }
  }

  Future<LatLng> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
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
          icon: const Icon(Icons.person, color: Colors.white),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                  const Color.fromARGB(255, 54, 54, 54))),
          onPressed: () {
            storage.getItem('token') != null
                ? navigateToScreen('/profile')
                : navigateToScreen('/login');
          },
        ),
      ],
    );
  }

  void navigateToScreen(String route) {
    Navigator.pushNamed(context, route).then((_) {
      setState(() {
        products = searchProductsByLocation(_currentPosition, _radius);
        if (_idCategory == null) {
          productsFiltered = products;
          return;
        }
        productsFiltered = products?.then((value) =>
            value.where((item) => item.categoryId == _idCategory).toList());
      });
    });
  }

  Widget getSubHeader() {
    return SliverToBoxAdapter(
        child: Column(
      children: [
        Row(
          children: [
            TextButton(
                onPressed: () {
                  if (storage.getItem('token') == null) {
                    Navigator.pushNamed(context, '/login');
                    _searchController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Debes iniciar sesión para vender')));
                    return;
                  }
                  _searchController.clear();
                  Navigator.pushNamed(context, '/product-form').then((_) {
                    setState(() {
                      products =
                          searchProductsByLocation(_currentPosition, _radius);
                      if (_idCategory == null) {
                        productsFiltered = products;
                        return;
                      }
                      productsFiltered = products?.then((value) => value
                          .where((item) => item.categoryId == _idCategory)
                          .toList());
                    });
                  });
                },
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
                onPressed: () {
                  storage.setItem('mapMode', 'filter');
                  Navigator.pushNamed(context, '/maps').then((_) {
                    if (storage.getItem('currentLocation') == null) {
                      return;
                    }
                    MapData mapData =
                        mapDataFromJson(storage.getItem('currentLocation'));
                    setState(() {
                      _currentPosition =
                          LatLng(double.parse(mapData.latitude),
                              double.parse(mapData.longitude));
                      _radius = mapData.radius ?? 1.5;
                      products =
                          searchProductsByLocation(_currentPosition, _radius);
                      if (_idCategory == null) {
                        productsFiltered = products;
                      } else {
                        productsFiltered = products?.then((value) => value
                            .where((item) => item.categoryId == _idCategory)
                            .toList());
                      }
                    });
                  });
                },
                icon: const Icon(Icons.location_on, color: Colors.white)),
          ],
        ),
        Container(
          margin:
              const EdgeInsets.only(top: 4, left: 12, right: 12, bottom: 16),
          height: 36,
          child: TextFormField(
            controller: _searchController,
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Buscar productos',
              hintStyle: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w400),
              filled: true,
              fillColor: Colors.grey.shade800,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          productsFiltered = products;
                        });
                      },
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.grey))
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              value = value.trim();
              setState(() {
                if (value.isEmpty) {
                  if (_idCategory == null) {
                    productsFiltered = products;
                    return;
                  }
                  productsFiltered = products?.then((value) => value
                      .where((item) => item.categoryId == _idCategory)
                      .toList());
                  return;
                }
                if (_idCategory == null) {
                  productsFiltered = products?.then((productList) => productList
                      .where((product) =>
                          product.name
                              .toLowerCase()
                              .contains(value.toLowerCase()) ||
                          product.description
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                      .toList());
                  return;
                }
                productsFiltered = products?.then((productList) => productList
                    .where((product) =>
                        product.categoryId == _idCategory &&
                        (product.name
                                .toLowerCase()
                                .contains(value.toLowerCase()) ||
                            product.description
                                .toLowerCase()
                                .contains(value.toLowerCase())))
                    .toList());
              });
            },
          ),
        ),
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
      return const Text('Error al cargar las categorias',
          style: TextStyle(color: Colors.white));
    }
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: List<Widget>.generate(categories.length, (index) {
        return ChoiceChip(
          label: Text(categories[index].name ?? '',
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
            setState(() {
              if (_idCategory == null) {
                productsFiltered = products;
                return;
              }
              productsFiltered = products?.then((value) => value
                  .where((item) => item.categoryId == _idCategory)
                  .toList());
            });
          },
        );
      }).toList(),
    );
  }

  Widget getProductListView() {
    return FutureBuilder<List<Product>>(
      future: productsFiltered,
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
          return const SliverToBoxAdapter(
              child:
                  Center(child: CircularProgressIndicator(color: Colors.blue)));
        }
      },
    );
  }

  Widget getProductView(Product? product) {
    if (product == null) {
      return const Text('Error');
    }
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-detail',
            arguments: {'id': product.id});
      },
      child: Column(
        children: [
          if (product.productimages != null &&
              product.productimages!.isNotEmpty) ...[
            Image.network(apiUrl + product.productimages![0].url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: (MediaQuery.of(context).size.width / 2) - 24,
                loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade600,
                child: Container(
                    width: double.infinity,
                    height: (MediaQuery.of(context).size.width / 2) - 24,
                    color: Colors.grey.shade800),
              );
            }),
          ] else ...[
            Container(
                width: double.infinity,
                height: (MediaQuery.of(context).size.width / 2) - 24,
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(Icons.image, color: Colors.white, size: 48),
                )),
          ],
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
