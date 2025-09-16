import 'dart:convert';

SupplierModel supplierModelFromJson(String str) =>
    SupplierModel.fromJson(json.decode(str));

String supplierModelToJson(SupplierModel data) => json.encode(data.toJson());

class SupplierModel {
  int id;
  String name;
  String clientNumber;
  String shipVia;

  SupplierModel({
    required this.id,
    required this.name,
    required this.clientNumber,
    required this.shipVia,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
        id: json["id"],
        name: json["name"],
        clientNumber: json["clientNumber"],
        shipVia: json["shipVia"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "clientNumber": clientNumber,
        "shipVia": shipVia,
      };
}
