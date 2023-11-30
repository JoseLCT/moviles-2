import 'dart:convert';

MapData mapDataFromJson(String str) => MapData.fromJson(json.decode(str));

String mapDataToJson(MapData data) => json.encode(data.toJson());

class MapData {
  String latitude;
  String longitude;
  double? zoom;
  double? radius;

  MapData({
    required this.latitude,
    required this.longitude,
    this.radius,
    this.zoom,
  });

  factory MapData.fromJson(Map<String, dynamic> json) => MapData(
        latitude: json["latitude"],
        longitude: json["longitude"],
        zoom: json["zoom"]?.toDouble() ?? 14,
        radius: json["radius"]?.toDouble() ?? 0.5,
      );

  Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
        "zoom": zoom,
        "radius": radius,
      };
}
