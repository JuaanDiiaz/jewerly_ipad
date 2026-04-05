import 'dart:convert';

CustomerPaymentModel customerPaymentModelFromJson(String str) =>
    CustomerPaymentModel.fromJson(json.decode(str));

String customerPaymentModelToJson(CustomerPaymentModel data) =>
    json.encode(data.toJson());

class CustomerPaymentModel {
  int id;
  int? customerId;
  int? salesOrderId;
  DateTime? paymentDate;
  dynamic amount;
  int? paymentMethodId;
  String? notes;

  CustomerPaymentModel({
    required this.id,
    this.customerId,
    this.salesOrderId,
    this.paymentDate,
    this.amount,
    this.paymentMethodId,
    this.notes,
  });

  factory CustomerPaymentModel.fromJson(Map<String, dynamic> json) => CustomerPaymentModel(
        id: json["id"],
        customerId: json["customerId"],
        salesOrderId: json["salesOrderId"],
        paymentDate: json["paymentDate"] == null ? null : DateTime.parse(json["paymentDate"]),
        amount: json["amount"],
        paymentMethodId: json["paymentMethodId"],
        notes: json["notes"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "customerId": customerId,
        "salesOrderId": salesOrderId,
        "paymentDate": paymentDate?.toIso8601String(),
        "amount": amount,
        "paymentMethodId": paymentMethodId,
        "notes": notes,
      };
}
