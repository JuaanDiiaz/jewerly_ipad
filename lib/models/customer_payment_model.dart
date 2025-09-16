import 'dart:convert';

CustomerPaymentModel customerPaymentModelFromJson(String str) =>
    CustomerPaymentModel.fromJson(json.decode(str));

String customerPaymentModelToJson(CustomerPaymentModel data) =>
    json.encode(data.toJson());

class CustomerPaymentModel {
  int id;
  int customerId;
  int salesOrderId;
  DateTime paymentDate;
  int amount;
  int paymentMethodId;
  String notes;
  Customer customer;

  CustomerPaymentModel({
    required this.id,
    required this.customerId,
    required this.salesOrderId,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethodId,
    required this.notes,
    required this.customer,
  });

  factory CustomerPaymentModel.fromJson(Map<String, dynamic> json) =>
      CustomerPaymentModel(
        id: json["id"],
        customerId: json["customerId"],
        salesOrderId: json["salesOrderId"],
        paymentDate: DateTime.parse(json["paymentDate"]),
        amount: json["amount"],
        paymentMethodId: json["paymentMethodId"],
        notes: json["notes"],
        customer: Customer.fromJson(json["customer"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "customerId": customerId,
        "salesOrderId": salesOrderId,
        "paymentDate": paymentDate.toIso8601String(),
        "amount": amount,
        "paymentMethodId": paymentMethodId,
        "notes": notes,
        "customer": customer.toJson(),
      };
}

class Customer {
  int id;
  String name;
  String email;
  String phone;
  String address;
  String city;
  String postalCode;
  String country;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
        address: json["address"],
        city: json["city"],
        postalCode: json["postalCode"],
        country: json["country"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "address": address,
        "city": city,
        "postalCode": postalCode,
        "country": country,
      };
}
