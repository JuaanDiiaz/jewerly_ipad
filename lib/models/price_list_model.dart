import 'dart:convert';

PriceListModel priceListModelFromJson(String str) =>
    PriceListModel.fromJson(json.decode(str));

String priceListModelToJson(PriceListModel data) => json.encode(data.toJson());

class PriceListModel {
  int id;

  /// The list's display name. The API field is `name` (`description` kept as
  /// a fallback for older payloads); /PriceList is read-only in the app, so
  /// toJson is only for symmetry.
  String description;

  PriceListModel({
    required this.id,
    required this.description,
  });

  factory PriceListModel.fromJson(Map<String, dynamic> json) => PriceListModel(
        id: json["id"],
        description: json["name"] ?? json["description"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": description,
      };
}