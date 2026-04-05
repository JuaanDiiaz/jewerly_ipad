import 'dart:convert';

InventoryModel inventoryModelFromJson(String str) =>
    InventoryModel.fromJson(json.decode(str));

String inventoryModelToJson(InventoryModel data) => json.encode(data.toJson());

class InventoryModel {
  int id;
  int? warehouseId;
  int? productId;
  String? location;
  dynamic weight;

  InventoryModel({
    required this.id,
    this.warehouseId,
    this.productId,
    this.location,
    this.weight,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
        id: json["id"],
        warehouseId: json["warehouseId"],
        productId: json["productId"],
        location: json["location"],
        weight: json["weight"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "warehouseId": warehouseId,
        "productId": productId,
        "location": location,
        "weight": weight,
      };
}
