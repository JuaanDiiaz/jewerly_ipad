import 'dart:convert';

SupplierProductModel supplierProductModelFromJson(String str) =>
    SupplierProductModel.fromJson(json.decode(str));

String supplierProductModelToJson(SupplierProductModel data) =>
    json.encode(data.toJson());

class SupplierProductModel {
  int id;
  int supplierId;
  int productId;
  String artCode;
  String styleCode;
  String description;
  int price;

  SupplierProductModel({
    required this.id,
    required this.supplierId,
    required this.productId,
    required this.artCode,
    required this.styleCode,
    required this.description,
    required this.price,
  });

  factory SupplierProductModel.fromJson(Map<String, dynamic> json) =>
      SupplierProductModel(
        id: json["id"],
        supplierId: json["supplierId"],
        productId: json["productId"],
        artCode: json["artCode"],
        styleCode: json["styleCode"],
        description: json["description"],
        price: json["price"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "supplierId": supplierId,
        "productId": productId,
        "artCode": artCode,
        "styleCode": styleCode,
        "description": description,
        "price": price,
      };
}
