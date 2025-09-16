import 'dart:convert';

PurchaseOrderDetailModel purchaseOrderDetailModelFromJson(String str) =>
    PurchaseOrderDetailModel.fromJson(json.decode(str));

String purchaseOrderDetailModelToJson(PurchaseOrderDetailModel data) =>
    json.encode(data.toJson());

class PurchaseOrderDetailModel {
  int id;
  int purchaseOrderId;
  int productId;
  int quantity;
  int unitPrice;
  int total;

  PurchaseOrderDetailModel({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory PurchaseOrderDetailModel.fromJson(Map<String, dynamic> json) =>
      PurchaseOrderDetailModel(
        id: json["id"],
        purchaseOrderId: json["purchaseOrderId"],
        productId: json["productId"],
        quantity: json["quantity"],
        unitPrice: json["unitPrice"],
        total: json["total"],
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
