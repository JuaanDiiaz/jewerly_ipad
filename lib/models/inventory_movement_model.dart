import 'dart:convert';

InventoryMovementModel inventoryMovementModelFromJson(String str) =>
    InventoryMovementModel.fromJson(json.decode(str));

String inventoryMovementModelToJson(InventoryMovementModel data) =>
    json.encode(data.toJson());

class InventoryMovementModel {
  int id;
  int productId;
  int warehouseId;
  String movementType;
  int quantity;
  DateTime movementDate;
  int purchaseOrderId;
  int salesOrderId;
  String manualEntryReason;
  String notes;

  InventoryMovementModel({
    required this.id,
    required this.productId,
    required this.warehouseId,
    required this.movementType,
    required this.quantity,
    required this.movementDate,
    required this.purchaseOrderId,
    required this.salesOrderId,
    required this.manualEntryReason,
    required this.notes,
  });

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) =>
      InventoryMovementModel(
        id: json["id"],
        productId: json["productId"],
        warehouseId: json["warehouseId"],
        movementType: json["movementType"],
        quantity: json["quantity"],
        movementDate: DateTime.parse(json["movementDate"]),
        purchaseOrderId: json["purchaseOrderId"],
        salesOrderId: json["salesOrderId"],
        manualEntryReason: json["manualEntryReason"],
        notes: json["notes"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "productId": productId,
        "warehouseId": warehouseId,
        "movementType": movementType,
        "quantity": quantity,
        "movementDate": movementDate.toIso8601String(),
        "purchaseOrderId": purchaseOrderId,
        "salesOrderId": salesOrderId,
        "manualEntryReason": manualEntryReason,
        "notes": notes,
      };
}
