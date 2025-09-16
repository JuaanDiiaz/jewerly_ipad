import 'dart:convert';

PriceListModel priceListModelFromJson(String str) =>
    PriceListModel.fromJson(json.decode(str));

String priceListModelToJson(PriceListModel data) => json.encode(data.toJson());

class PriceListModel {
  int id;
  String description;

  PriceListModel({
    required this.id,
    required this.description,
  });

  factory PriceListModel.fromJson(Map<String, dynamic> json) => PriceListModel(
        id: json["id"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "description": description,
      };
}
