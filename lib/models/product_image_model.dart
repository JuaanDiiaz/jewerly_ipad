import 'dart:convert';

ProductImageModel productImageModelFromJson(String str) =>
    ProductImageModel.fromJson(json.decode(str));

String productImageModelToJson(ProductImageModel data) =>
    json.encode(data.toJson());

class ProductImageModel {
  int id;
  int productId;
  String imageUrl;
  String description;

  ProductImageModel({
    required this.id,
    required this.productId,
    required this.imageUrl,
    required this.description,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) =>
      ProductImageModel(
        id: json["id"],
        productId: json["productId"],
        imageUrl: json["imageUrl"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "productId": productId,
        "imageUrl": imageUrl,
        "description": description,
      };
}
