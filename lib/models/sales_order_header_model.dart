import 'dart:convert';

SalesOrderHeaderModel salesOrderHeaderModelFromJson(String str) =>
    SalesOrderHeaderModel.fromJson(json.decode(str));

String salesOrderHeaderModelToJson(SalesOrderHeaderModel data) =>
    json.encode(data.toJson());

class SalesOrderHeaderModel {
  int id;
  DateTime? saleDate;
  int? customerId;
  dynamic subtotal;
  // Legacy rows predate server-side tax and are null here.
  dynamic taxAmount;
  dynamic total;
  int? paymentMethodId;
  String? notes;
  String? salespersonName;

  SalesOrderHeaderModel({
    required this.id,
    this.saleDate,
    this.customerId,
    this.subtotal,
    this.taxAmount,
    this.total,
    this.paymentMethodId,
    this.notes,
    this.salespersonName,
  });

  factory SalesOrderHeaderModel.fromJson(Map<String, dynamic> json) =>
      SalesOrderHeaderModel(
        id: json["id"],
        saleDate: json["saleDate"] == null ? null : DateTime.parse(json["saleDate"]),
        customerId: json["customerId"],
        subtotal: json["subtotal"],
        taxAmount: json["taxAmount"],
        total: json["total"],
        paymentMethodId: json["paymentMethodId"],
        notes: json["notes"],
        salespersonName: json["salespersonName"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "saleDate": saleDate?.toIso8601String(),
        "customerId": customerId,
        "subtotal": subtotal,
        "taxAmount": taxAmount,
        "total": total,
        "paymentMethodId": paymentMethodId,
        "notes": notes,
        "salespersonName": salespersonName,
      };
}
