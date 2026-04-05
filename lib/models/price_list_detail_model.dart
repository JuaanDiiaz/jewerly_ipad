import 'dart:convert';

PriceListDetailModel priceListDetailModelFromJson(String str) =>
    PriceListDetailModel.fromJson(json.decode(str));

String priceListDetailModelToJson(PriceListDetailModel data) => json.encode(data.toJson());

class PriceListDetailModel {
  int id;
  int? priceListId;
  int? productId;
  dynamic price;
  DateTime? validFrom;
  DateTime? validTo;

  PriceListDetailModel({
    required this.id,
    this.priceListId,
    this.productId,
    this.price,
    this.validFrom,
    this.validTo,
  });

  factory PriceListDetailModel.fromJson(Map<String, dynamic> json) => PriceListDetailModel(
        id: json["id"],
        priceListId: json["priceListId"],
        productId: json["productId"],
        price: json["price"],
        validFrom: json["validFrom"] == null ? null : DateTime.parse(json["validFrom"]),
        validTo: json["validTo"] == null ? null : DateTime.parse(json["validTo"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "priceListId": priceListId,
        "productId": productId,
        "price": price,
        "validFrom": validFrom?.toIso8601String(),
        "validTo": validTo?.toIso8601String(),
      };
}
