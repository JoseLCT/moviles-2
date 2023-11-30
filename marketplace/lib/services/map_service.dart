import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace/models/place_autocomplete_model.dart';
import 'package:marketplace/models/place_location_model.dart';

final String mapsApiKey = dotenv.get('GOOGLE_MAPS_API_KEY');

Future<PlaceAutocomplete?> search(String query) async {
  Uri uri = Uri.https(
    'maps.googleapis.com',
    '/maps/api/place/autocomplete/json',
    {
      'input': query,
      'key': mapsApiKey,
    },
  );
  try {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      PlaceAutocomplete places = placeAutocompleteFromJson(response.body);
      return places;
    }
  } catch (e) {
    debugPrint(e.toString());
  }
  return null;
}

Future<PlaceLocation> getPlaceLocation(String placeId) async {
  Uri uri = Uri.https(
    'maps.googleapis.com',
    '/maps/api/place/details/json',
    {
      'fields': 'geometry',
      'place_id': placeId,
      'key': mapsApiKey,
    },
  );
  try {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      PlaceLocation placeLocation = placeLocationFromJson(response.body);
      return placeLocation;
    }
  } catch (e) {
    debugPrint(e.toString());
  }
  return PlaceLocation();
}

Future<LatLng> getCurrentPosition() async {
  bool locationEnable = await Geolocator.isLocationServiceEnabled();
  if (!locationEnable) {
    return const LatLng(-17.7837702, -63.18416);
  }
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  return LatLng(position.latitude, position.longitude);
}