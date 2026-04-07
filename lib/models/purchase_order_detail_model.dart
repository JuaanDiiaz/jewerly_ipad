import 'dart:convert';

PurchaseOrderDetailModel purchaseOrderDetailModelFromJson(String str) =>
    PurchaseOrderDetailModel.fromJson(json.decode(str));

String purchaseOrderDetailModelToJson(PurchaseOrderDetailModel data) =>
    json.encode(data.toJson());

class PurchaseOrderDetailModel {
  int id;
  int? purchaseOrderId;
  int? productId;
  int? quantity;
  double? unitPrice;
  double? total;

  PurchaseOrderDetailModel({
    required this.id,
    this.purchaseOrderId,
    this.productId,
    this.quantity,
    this.unitPrice,
    this.total,
  });

  factory PurchaseOrderDetailModel.fromJson(Map<String, dynamic> json) =>
      PurchaseOrderDetailModel(
        id: json["id"] ?? 0,
        purchaseOrderId: json["purchaseOrderId"],
        productId: json["productId"],
        quantity: json["quantity"],
        unitPrice: json["unitPrice"] != null
            ? (json["unitPrice"] is int ? (json["unitPrice"] as int).toDouble() : json["unitPrice"])
            : null,
        total: json["total"] != null
            ? (json["total"] is int ? (json["total"] as int).toDouble() : json["total"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "purchaseOrderId": purchaseOrderId,
        "productId": productId,
        "quantity": quantity,
        "unitPrice": unitPrice,
        "total": total,
      };
}