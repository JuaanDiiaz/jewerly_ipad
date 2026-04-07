import 'dart:convert';

PurchaseOrderHeaderModel purchaseOrderHeaderModelFromJson(String str) =>
    PurchaseOrderHeaderModel.fromJson(json.decode(str));

String purchaseOrderHeaderModelToJson(PurchaseOrderHeaderModel data) =>
    json.encode(data.toJson());

class PurchaseOrderHeaderModel {
  int id;
  int? supplierId;
  DateTime? orderDate;
  String? status;
  double? total;
  DateTime? receptionDate;
  String? notes;

  PurchaseOrderHeaderModel({
    required this.id,
    this.supplierId,
    this.orderDate,
    this.status,
    this.total,
    this.receptionDate,
    this.notes,
  });

  factory PurchaseOrderHeaderModel.fromJson(Map<String, dynamic> json) =>
      PurchaseOrderHeaderModel(
        id: json["id"] ?? 0,
        supplierId: json["supplierId"],
        orderDate: json["orderDate"] != null ? DateTime.parse(json["orderDate"]) : null,
        status: json["status"],
        total: json["total"] != null ? (json["total"] is int ? (json["total"] as int).toDouble() : json["total"]) : null,
        receptionDate: json["receptionDate"] != null ? DateTime.parse(json["receptionDate"]) : null,
        notes: json["notes"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "supplierId": supplierId,
        "orderDate": orderDate?.toIso8601String(),
        "status": status,
        "total": total,
        "receptionDate": receptionDate?.toIso8601String(),
        "notes": notes,
      };
}