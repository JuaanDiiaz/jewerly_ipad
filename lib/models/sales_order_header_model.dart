import 'dart:convert';

SalesOrderHeaderModel salesOrderHeaderModelFromJson(String str) =>
    SalesOrderHeaderModel.fromJson(json.decode(str));

String salesOrderHeaderModelToJson(SalesOrderHeaderModel data) =>
    json.encode(data.toJson());

class SalesOrderHeaderModel {
  int id;
  DateTime saleDate;
  int customerId;
  int total;
  int paymentMethodId;
  String notes;

  SalesOrderHeaderModel({
    required this.id,
    required this.saleDate,
    required this.customerId,
    required this.total,
    required this.paymentMethodId,
    required this.notes,
  });

  factory SalesOrderHeaderModel.fromJson(Map<String, dynamic> json) =>
      SalesOrderHeaderModel(
        id: json["id"],
        saleDate: DateTime.parse(json["saleDate"]),
        customerId: json["customerId"],
        total: json["total"],
        paymentMethodId: json["paymentMethodId"],
        notes: json["notes"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "saleDate": saleDate.toIso8601String(),
        "customerId": customerId,
        "total": total,
        "paymentMethodId": paymentMethodId,
        "notes": notes,
      };
}
