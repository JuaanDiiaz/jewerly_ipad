import 'dart:convert';

CategoryModel categoryModelFromJson(String str) =>
    CategoryModel.fromJson(json.decode(str));

String categoryModelToJson(CategoryModel data) => json.encode(data.toJson());

class CategoryModel {
  int id;
  int idParentCategory;
  String categoryNumber;
  String description;
  String extraInformation;

  CategoryModel({
    required this.id,
    required this.idParentCategory,
    required this.categoryNumber,
    required this.description,
    required this.extraInformation,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json["id"],
        idParentCategory: json["idParentCategory"],
        categoryNumber: json["categoryNumber"],
        description: json["description"],
        extraInformation: json["extraInformation"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "idParentCategory": idParentCategory,
        "categoryNumber": categoryNumber,
        "description": description,
        "extraInformation": extraInformation,
      };
}
