import 'dart:convert';

PaymentMovementModel paymentMovementModelFromJson(String str) =>
    PaymentMovementModel.fromJson(json.decode(str));

String paymentMovementModelToJson(PaymentMovementModel data) =>
    json.encode(data.toJson());

class PaymentMovementModel {
  int id;
  String description;

  PaymentMovementModel({
    required this.id,
    required this.description,
  });

  factory PaymentMovementModel.fromJson(Map<String, dynamic> json) =>
      PaymentMovementModel(
        id: json["id"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "description": description,
      };
}
