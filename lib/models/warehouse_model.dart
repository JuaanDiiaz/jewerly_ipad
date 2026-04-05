import 'dart:convert';

WarehouseModel warehouseModelFromJson(String str) =>
    WarehouseModel.fromJson(json.decode(str));

String warehouseModelToJson(WarehouseModel data) => json.encode(data.toJson());

class WarehouseModel {
  int id;
  String? name;

  WarehouseModel({
    required this.id,
    this.name,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) => WarehouseModel(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}
