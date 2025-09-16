import 'dart:convert';

PriceListDetailModel priceListDetailModelFromJson(String str) =>
    PriceListDetailModel.fromJson(json.decode(str));

String priceListDetailModelToJson(PriceListDetailModel data) =>
    json.encode(data.toJson());

class PriceListDetailModel {
  int id;
  int priceListId;
  int productId;
  int price;
  DateTime validFrom;
  DateTime validTo;

  PriceListDetailModel({
    required this.id,
    required this.priceListId,
    required this.productId,
    required this.price,
    required this.validFrom,
    required this.validTo,
  });

  factory PriceListDetailModel.fromJson(Map<String, dynamic> json) =>
      PriceListDetailModel(
        id: json["id"],
        priceListId: json["priceListId"],
        productId: json["productId"],
        price: json["price"],
        validFrom: DateTime.parse(json["validFrom"]),
        validTo: DateTime.parse(json["validTo"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "priceListId": priceListId,
        "productId": productId,
        "price": price,
        "validFrom": validFrom.toIso8601String(),
        "validTo": validTo.toIso8601String(),
      };
}
