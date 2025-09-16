import 'dart:convert';

PurchaseOrderHeaderModel purchaseOrderHeaderModelFromJson(String str) =>
    PurchaseOrderHeaderModel.fromJson(json.decode(str));

String purchaseOrderHeaderModelToJson(PurchaseOrderHeaderModel data) =>
    json.encode(data.toJson());

class PurchaseOrderHeaderModel {
  int id;
  int supplierId;
  DateTime orderDate;
  String status;
  int total;
  DateTime receptionDate;
  String notes;

  PurchaseOrderHeaderModel({
    required this.id,
    required this.supplierId,
    required this.orderDate,
    required this.status,
    required this.total,
    required this.receptionDate,
    required this.notes,
  });

  factory PurchaseOrderHeaderModel.fromJson(Map<String, dynamic> json) =>
      PurchaseOrderHeaderModel(
        id: json["id"],
        supplierId: json["supplierId"],
        orderDate: DateTime.parse(json["orderDate"]),
        status: json["status"],
        total: json["total"],
        receptionDate: DateTime.parse(json["receptionDate"]),
        notes: json["notes"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "supplierId": supplierId,
        "orderDate": orderDate.toIso8601String(),
        "status": status,
        "total": total,
        "receptionDate": receptionDate.toIso8601String(),
        "notes": notes,
      };
}
