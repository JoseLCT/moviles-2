import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:localstorage/localstorage.dart';
import 'package:marketplace/models/category_model.dart';
import 'package:marketplace/models/image_preview_model.dart';
import 'package:marketplace/models/map_data_model.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/models/user_model.dart';
import 'package:marketplace/services/auth_service.dart';
import 'package:marketplace/services/category_service.dart';
import 'package:marketplace/services/map_service.dart';
import 'package:marketplace/services/product_service.dart';
import 'package:shimmer/shimmer.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final LocalStorage storage = LocalStorage('marketplace_app');
  final _formKey = GlobalKey<FormState>();
  final List<Category> categories = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int? idCategory;
  LatLng location = const LatLng(-17.7837702, -63.18416);
  String? mapUrl;
  Future<Product?>? product;
  int id = 0;
  List<ImagePreview> images = [];
  final String apiUrl = dotenv.get('API_URL');
  List<int> imagesToDelete = [];
  User? user;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (storage.getItem('currentLocation') != null) {
      MapData mapData = mapDataFromJson(storage.getItem('currentLocation'));
      storage
          .setItem('productLocation', mapDataToJson(mapData))
          .then((value) => storage.setItem('mapMode', 'product'));
      location = LatLng(
          double.parse(mapData.latitude), double.parse(mapData.longitude));
    }
    getUser(storage.getItem('token'))
        .then((value) => user = value)
        .catchError((error) {
      if (error.toString() == '401') {
        storage.clear().then((value) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/', (route) => false);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    id = arguments['id'] ?? 0;
    if (id != 0 && product == null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    product = getProduct(id);
    setState(() {
      product?.then((value) {
        _titleController.text = value?.name ?? '';
        _priceController.text = value?.price.toString() ?? '';
        _descriptionController.text = value?.description ?? '';
        idCategory = value?.categoryId ?? 0;
        for (var img in value?.productimages ?? []) {
          ImagePreview imgPreview = ImagePreview(type: 0, productImage: img);
          images.add(imgPreview);
        }
      });
    });
  }

  void _loadCategories() {
    setState(() {
      getCategories().then((categoryList) {
        categories.addAll(categoryList);
      });
    });
  }

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
        title: Text(id == 0 ? 'Nueva publicación' : 'Editar publicación',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        centerTitle: true,
        actions: [
          TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (images.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Debe seleccionar al menos una imagen')));
                    return;
                  }
                  saveProduct();
                }
              },
              child: Text(id == 0 ? 'Publicar' : 'Guardar',
                  style: const TextStyle(
                      color: Color.fromARGB(255, 0, 122, 255), fontSize: 16))),
        ],
        backgroundColor: Colors.grey.shade900,
      ),
      body: FutureBuilder(
          future: product,
          builder: (BuildContext context, AsyncSnapshot<Product?> snapshot) {
            if (snapshot.hasData) {
              return getFormView();
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('${snapshot.error}',
                      style: const TextStyle(color: Colors.white)));
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (id == 0) {
              return getFormView();
            } else {
              return const Center(
                  child: Text('No se pudo cargar la publicación',
                      style: TextStyle(color: Colors.white)));
            }
          }),
    );
  }

  Future<void> saveProduct() async {
    String token = storage.getItem('token');
    Product product = Product(
      name: _titleController.text,
      description: _descriptionController.text,
      price: int.parse(_priceController.text),
      latitude: location.latitude.toString(),
      longitude: location.longitude.toString(),
      categoryId: idCategory!,
      userId: user!.id,
      status: 1,
      sold: 0,
    );
    if (id == 0) {
      insertProduct(product, token).then((productResponse) async {
        for (var img in images) {
          if (img.file == null) {
            continue;
          }
          await insertImage(productResponse.id!, img.file!.path, token)
              .then((value) => null)
              .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Error al subir las imágenes')));
          });
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Color.fromARGB(255, 18, 87, 189),
              content: Text('Publicación creada')));
          Navigator.pop(context);
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red, content: Text(error.toString())));
      });
    } else {
      updateProduct(product, token, id).then((value) async {
        for (var img in images) {
          if (img.file == null) {
            continue;
          }
          await insertImage(id, img.file!.path, token)
              .then((value) => null)
              .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Error al subir las imágenes')));
          });
        }
        for (var imgId in imagesToDelete) {
          deleteImage(imgId, token).then((value) => null).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Error al eliminar las imágenes')));
          });
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Color.fromARGB(255, 18, 87, 189),
              content: Text('Publicación actualizada')));
          Navigator.pop(context);
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red, content: Text(error.toString())));
      });
    }
  }

  Widget getFormView() {
    return SingleChildScrollView(
      child: Container(
          margin:
              const EdgeInsets.only(top: 20, left: 12, right: 12, bottom: 20),
          child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (images.isNotEmpty) ...[
                        SizedBox(
                            width: 100,
                            height: 100,
                            child: IconButton(
                              onPressed: () {
                                _pickImage(context);
                              },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: const BorderSide(color: Colors.grey),
                              ),
                              iconSize: 24,
                              icon: const Icon(Icons.add_to_photos_rounded,
                                  color: Colors.grey),
                            )),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (BuildContext context, int index) {
                                return getImagePreview(images[index]);
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: SizedBox(
                              height: 100,
                              child: TextButton.icon(
                                onPressed: () {
                                  _pickImage(context);
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                ),
                                icon: const Icon(Icons.add_to_photos_rounded,
                                    color: Colors.grey),
                                label: const Text('Agregar fotos',
                                    style: TextStyle(color: Colors.grey)),
                              )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide:
                            BorderSide(color: Color.fromARGB(255, 0, 122, 255)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      errorStyle: TextStyle(color: Colors.red),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    cursorColor: const Color.fromARGB(255, 0, 122, 255),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un título';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide:
                            BorderSide(color: Color.fromARGB(255, 0, 122, 255)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      errorStyle: TextStyle(color: Colors.red),
                      prefix:
                          Text('Bs. ', style: TextStyle(color: Colors.grey)),
                    ),
                    cursorColor: const Color.fromARGB(255, 0, 122, 255),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un precio';
                      }
                      try {
                        int price = int.parse(value);
                        if (price < 0) {
                          return 'El precio debe ser mayor a 0';
                        }
                        if (price > 1000000) {
                          return 'El precio debe ser menor a Bs. 1.000.000';
                        }
                      } catch (e) {
                        return 'Ingresa un precio válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField(
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        idCategory = value;
                      });
                    },
                    iconDisabledColor: Colors.grey,
                    iconEnabledColor: Colors.grey,
                    value: idCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 0, 122, 255))),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      errorStyle: TextStyle(color: Colors.red),
                    ),
                    dropdownColor: const Color.fromARGB(255, 46, 46, 46),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona una categoría';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide:
                            BorderSide(color: Color.fromARGB(255, 0, 122, 255)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      errorStyle: TextStyle(color: Colors.red),
                    ),
                    cursorColor: const Color.fromARGB(255, 0, 122, 255),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una descripción';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade600),
                  const SizedBox(height: 12),
                  const Text('Ubicación',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  getMapCard(),
                ],
              ))),
    );
  }

  Widget getMapCard() {
    return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: GestureDetector(
          onTap: () {
            storage.setItem('mapMode', 'product').then((_) {
              Navigator.pushNamed(context, '/maps').then((_) {
                setState(() {
                  if (storage.getItem('productLocation') == null) {
                    return;
                  }
                  MapData mapData =
                      mapDataFromJson(storage.getItem('productLocation'));
                  location = LatLng(double.parse(mapData.latitude),
                      double.parse(mapData.longitude));
                  mapUrl = 'https://maps.googleapis.com/maps/api/staticmap?'
                      'center=${location.latitude},${location.longitude}&'
                      'zoom=14&'
                      'markers=size:mid%7Ccolor:red%7C${location.latitude},${location.longitude}&'
                      'size=900x400&'
                      'key=$mapsApiKey';
                });
              });
            });
          },
          child: Image.network(
              mapUrl ??
                  'https://maps.googleapis.com/maps/api/staticmap?'
                      'center=${location.latitude},${location.longitude}&'
                      'zoom=14&'
                      'markers=size:mid%7Ccolor:red%7C${location.latitude},${location.longitude}&'
                      'size=900x400&'
                      'key=$mapsApiKey',
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade800,
              highlightColor: Colors.grey.shade700,
              child: Container(
                width: double.infinity,
                height: 120,
                color: Colors.grey.shade800,
              ),
            );
          }),
        ));
  }

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    setState(() {
      ImagePreview imgPreview = ImagePreview(type: 1, file: image);
      images.add(imgPreview);
    });
  }

  Future<void> _showFullScreenImage(String path, int type) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        if (type == 0) {
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
        } else {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: SizedBox.expand(
              child: Image.file(
                File(path),
                width: MediaQuery.of(context).size.width,
              ),
            ),
          );
        }
      },
    );
  }

  Widget getImagePreview(ImagePreview imgPreview) {
    Key dropDownKey = UniqueKey();
    return GestureDetector(
        onTap: () {
          if (imgPreview.type == 0) {
            _showFullScreenImage(
                apiUrl + imgPreview.productImage!.url, imgPreview.type);
          } else {
            _showFullScreenImage(imgPreview.file!.path, imgPreview.type);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          width: MediaQuery.of(context).size.width * 0.3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              if (imgPreview.type == 0) ...[
                Positioned.fill(
                    child: Image.network(apiUrl + imgPreview.productImage!.url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade800,
                    highlightColor: Colors.grey.shade700,
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      color: Colors.grey.shade800,
                    ),
                  );
                })),
              ] else ...[
                Positioned.fill(
                    child: Image.file(
                  File(imgPreview.file!.path),
                  fit: BoxFit.cover,
                )),
              ],
              Positioned(
                  top: 2,
                  right: 2,
                  child: SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.6),
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.zero,
                        color: Colors.white,
                        onPressed: () {
                          setState(() {
                            if (imgPreview.type == 0) {
                              imagesToDelete.add(imgPreview.productImage!.id);
                            }
                            images.remove(imgPreview);
                          });
                        },
                      ))),
              if (id == 0) ...[
                Positioned(
                    top: 2,
                    left: 2,
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: DropdownButtonFormField(
                        key: dropDownKey,
                        items: List.generate(images.length, (index) {
                          return DropdownMenuItem(
                              value: index,
                              child: Center(
                                  child: Text(
                                (index + 1).toString(),
                                textAlign: TextAlign.center,
                              )));
                        }),
                        onChanged: (value) {
                          setState(() {
                            int index = images.indexOf(imgPreview);
                            int newIndex = value ?? 0;
                            ImagePreview image = images.removeAt(index);
                            images.insert(newIndex, image);
                          });
                        },
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.6),
                        ),
                        isExpanded: true,
                        icon: const Visibility(
                            visible: false, child: Icon(Icons.arrow_drop_down)),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: const Color.fromARGB(255, 46, 46, 46),
                        value: images.indexOf(imgPreview),
                      ),
                    )),
              ],
            ],
          ),
        ));
  }
}
