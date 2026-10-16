import 'dart:convert';

TaxRateModel taxRateModelFromJson(String str) =>
    TaxRateModel.fromJson(json.decode(str));

String taxRateModelToJson(TaxRateModel data) => json.encode(data.toJson());

/// One sales tax rate. A null [categoryId] marks the fallback rate applied to
/// products with no category (the "default" row). [rate] is a fraction
/// (0.16 = 16%) — prices are IVA-exclusive, so tax is added on top.
class TaxRateModel {
  int id;
  int? categoryId;
  String? name;
  double? rate;
  bool isActive;

  TaxRateModel({
    required this.id,
    this.categoryId,
    this.name,
    this.rate,
    required this.isActive,
  });

  factory TaxRateModel.fromJson(Map<String, dynamic> json) => TaxRateModel(
        id: json["id"],
        categoryId: json["categoryId"],
        name: json["name"],
        rate: json["rate"] == null ? null : (json["rate"] as num).toDouble(),
        isActive: json["isActive"] == true,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "categoryId": categoryId,
        "name": name,
        "rate": rate,
        "isActive": isActive,
      };
}