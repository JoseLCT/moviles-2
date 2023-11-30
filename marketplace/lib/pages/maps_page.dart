import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:marketplace/models/map_data_model.dart';
import 'package:marketplace/models/place_autocomplete_model.dart';
import 'package:marketplace/models/place_location_model.dart';
import 'package:marketplace/services/map_service.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final LocalStorage storage = LocalStorage('marketplace_app');
  double _radius = 1.5;
  double _zoom = 14;
  LatLng _location = const LatLng(-17.7837702, -63.18416);
  final TextEditingController _searchController = TextEditingController();
  List<Prediction>? _places;
  GoogleMapController? _mapsController;
  String _mode = 'filter';

  @override
  void initState() {
    super.initState();
    loadMapData();
  }

  void loadMapData() {
    String storageMapItem = 'currentLocation';
    if (storage.getItem('mapMode') != null) {
      _mode = storage.getItem('mapMode');
      if (_mode == 'filter') {
        storageMapItem = 'currentLocation';
      } else if (_mode == 'product') {
        storageMapItem = 'productLocation';
      }
      if (storage.getItem(storageMapItem) != null) {
        MapData mapData = mapDataFromJson(storage.getItem(storageMapItem));
        setState(() {
          _location = LatLng(
            double.parse(mapData.latitude),
            double.parse(mapData.longitude),
          );
          if (_mode == 'filter') {
            _radius = mapData.radius!;
          } else if (_mode == 'product') {
            _radius = 1.5;
          }
          _zoom = 14 - (_radius / 3);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        centerTitle: true,
        title: const Text('Ubicación', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Form(
            child: Container(
              margin: const EdgeInsets.only(
                  top: 4, left: 12, right: 12, bottom: 16),
              height: 36,
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar una ubicación',
                  hintStyle: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w400),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  searchPlace();
                },
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  GoogleMap(
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      _mapsController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _location,
                      zoom: _zoom,
                    ),
                    circles: {
                      Circle(
                        circleId: const CircleId('1'),
                        center: _location,
                        radius: _radius * 1000,
                        fillColor: Colors.blue.withOpacity(0.2),
                        strokeColor: Colors.blue,
                        strokeWidth: 2,
                        visible: _mode == 'filter',
                      ),
                    },
                    onCameraIdle: () {
                      setState(() {
                        _mapsController?.getVisibleRegion().then((value) {
                          final LatLngBounds visibleRegion = value;
                          final LatLng centerLatLng = LatLng(
                            (visibleRegion.northeast.latitude +
                                    visibleRegion.southwest.latitude) /
                                2,
                            (visibleRegion.northeast.longitude +
                                    visibleRegion.southwest.longitude) /
                                2,
                          );
                          _location = centerLatLng;
                        });
                      });
                    },
                  ),
                  Positioned(
                    left: constraints.maxWidth / 2 - 12,
                    top: constraints.maxHeight / 2 - 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.circle,
                          color: Color.fromARGB(255, 8, 102, 255), size: 23),
                    ),
                  ),
                  if (_places != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.grey.shade900,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _places!.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              onTap: () {
                                onPlaceTap(_places![index].placeId);
                              },
                              title: Text(
                                _places![index].description,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          if (_mode == 'filter')
            Container(
              margin: const EdgeInsets.only(top: 16, left: 12, right: 12),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Radio de búsqueda',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Encotrar productos en un radio de: ${_radius.toStringAsFixed(1)} km',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  Slider(
                    min: 1,
                    max: 10,
                    value: _radius,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey.shade700,
                    onChanged: (value) {
                      setState(() {
                        _radius = value;
                        _zoom = 14 - (value / 3);
                        moveMapCamera();
                      });
                    },
                  ),
                ],
              ),
            ),
          Container(
            margin: EdgeInsets.only(
                bottom: 16,
                left: 12,
                right: 12,
                top: _mode == 'filter' ? 0 : 12),
            child: TextButton(
              onPressed: () {
                String validRadius = _radius.toStringAsFixed(1);
                MapData mapData = MapData(
                  latitude: _location.latitude.toString(),
                  longitude: _location.longitude.toString(),
                  radius: double.parse(validRadius),
                  zoom: _zoom,
                );
                String storageMapItem = 'currentLocation';
                if (_mode == 'product') {
                  storageMapItem = 'productLocation';
                } else if (_mode == 'filter') {
                  storageMapItem = 'currentLocation';
                }
                storage
                    .setItem(storageMapItem, mapDataToJson(mapData))
                    .then((_) {
                  Navigator.of(context).pop();
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 8, 102, 255),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  const Text('Aplicar', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void searchPlace() async {
    if (_searchController.text.isEmpty) {
      cleanSearch();
      return;
    }
    search(_searchController.text).then((response) {
      if (response != null) {
        setState(() {
          _places = response.predictions;
        });
      }
    });
  }

  void onPlaceTap(String placeId) async {
    PlaceLocation placeLocation = await getPlaceLocation(placeId);
    setState(() {
      _location = LatLng(
        placeLocation.result!.geometry.location.lat,
        placeLocation.result!.geometry.location.lng,
      );
      _zoom = 14;
      cleanSearch();
      moveMapCamera();
    });
  }

  void moveMapCamera() {
    if (_mapsController != null) {
      _mapsController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _location,
            zoom: _zoom,
          ),
        ),
      );
    }
  }

  void cleanSearch() {
    setState(() {
      _places = null;
      _searchController.text = '';
    });
  }
}
