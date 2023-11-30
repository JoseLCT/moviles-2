import 'dart:convert';

PlaceLocation placeLocationFromJson(String str) =>
    PlaceLocation.fromJson(json.decode(str));

String placeLocationToJson(PlaceLocation data) => json.encode(data.toJson());

class PlaceLocation {
  Result? result;
  String? status;

  PlaceLocation({
    this.result,
    this.status,
  });

  factory PlaceLocation.fromJson(Map<String, dynamic> json) => PlaceLocation(
        result: Result.fromJson(json["result"]),
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "result": result?.toJson(),
        "status": status,
      };
}

class Result {
  Geometry geometry;

  Result({
    required this.geometry,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        geometry: Geometry.fromJson(json["geometry"]),
      );

  Map<String, dynamic> toJson() => {
        "geometry": geometry.toJson(),
      };
}

class Geometry {
  Location location;

  Geometry({
    required this.location,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) => Geometry(
        location: Location.fromJson(json["location"]),
      );

  Map<String, dynamic> toJson() => {
        "location": location.toJson(),
      };
}

class Location {
  double lat;
  double lng;

  Location({
    required this.lat,
    required this.lng,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        lat: json["lat"]?.toDouble(),
        lng: json["lng"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "lat": lat,
        "lng": lng,
      };
}
