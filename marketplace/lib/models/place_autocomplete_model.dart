import 'dart:convert';

PlaceAutocomplete placeAutocompleteFromJson(String str) => PlaceAutocomplete.fromJson(json.decode(str));

String placeAutocompleteToJson(PlaceAutocomplete data) => json.encode(data.toJson());

class PlaceAutocomplete {
    List<Prediction>? predictions;
    String? status;

    PlaceAutocomplete({
        this.predictions,
        this.status,
    });

    factory PlaceAutocomplete.fromJson(Map<String, dynamic> json) => PlaceAutocomplete(
        predictions: List<Prediction>.from(json["predictions"].map((x) => Prediction.fromJson(x))),
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "predictions": List<dynamic>.from(predictions?.map((x) => x.toJson()) ?? []),
        "status": status,
    };
}

class Prediction {
    String description;
    String placeId;
    String reference;

    Prediction({
        required this.description,
        required this.placeId,
        required this.reference,
    });

    factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
        description: json["description"],
        placeId: json["place_id"],
        reference: json["reference"],
    );

    Map<String, dynamic> toJson() => {
        "description": description,
        "place_id": placeId,
        "reference": reference,
    };
}