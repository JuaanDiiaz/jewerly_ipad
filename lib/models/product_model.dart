import 'dart:convert';

ProductModel productModelFromJson(String str) =>
    ProductModel.fromJson(json.decode(str));

String productModelToJson(ProductModel data) => json.encode(data.toJson());

class ProductModel {
  int id;
  String? description;
  String? picture;

  ProductModel({
    required this.id,
    this.description,
    this.picture,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json["id"],
        description: json["description"],
        picture: json["picture"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "description": description,
        "picture": picture,
      };

  ProductModel copy() => ProductModel(
        id: id,
        description: description,
        picture: picture,
      );
}