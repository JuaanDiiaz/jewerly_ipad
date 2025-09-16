import 'dart:convert';

SalesOrderDetailModel salesOrderDetailModelFromJson(String str) =>
    SalesOrderDetailModel.fromJson(json.decode(str));

String salesOrderDetailModelToJson(SalesOrderDetailModel data) =>
    json.encode(data.toJson());

class SalesOrderDetailModel {
  int id;
  int salesOrderId;
  int productId;
  int quantity;
  int unitPrice;
  int total;

  SalesOrderDetailModel({
    required this.id,
    required this.salesOrderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory SalesOrderDetailModel.fromJson(Map<String, dynamic> json) =>
      SalesOrderDetailModel(
        id: json["id"],
        salesOrderId: json["salesOrderId"],
        productId: json["productId"],
        quantity: json["quantity"],
        unitPrice: json["unitPrice"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "salesOrderId": salesOrderId,
        "productId": productId,
        "quantity": quantity,
        "unitPrice": unitPrice,
        "total": total,
      };
}
