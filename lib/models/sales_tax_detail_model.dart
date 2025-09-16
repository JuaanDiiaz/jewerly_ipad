import 'dart:convert';

SalesTaxDetailModel salesTaxDetailModelFromJson(String str) =>
    SalesTaxDetailModel.fromJson(json.decode(str));

String salesTaxDetailModelToJson(SalesTaxDetailModel data) =>
    json.encode(data.toJson());

class SalesTaxDetailModel {
  int id;
  int salesOrderId;
  String taxType;
  int taxAmount;

  SalesTaxDetailModel({
    required this.id,
    required this.salesOrderId,
    required this.taxType,
    required this.taxAmount,
  });

  factory SalesTaxDetailModel.fromJson(Map<String, dynamic> json) =>
      SalesTaxDetailModel(
        id: json["id"],
        salesOrderId: json["salesOrderId"],
        taxType: json["taxType"],
        taxAmount: json["taxAmount"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "salesOrderId": salesOrderId,
        "taxType": taxType,
        "taxAmount": taxAmount,
      };
}
