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
  int? purchaseOrderId;
  int? salesOrderId;
  String? manualEntryReason;
  String? notes;

  InventoryMovementModel({
    required this.id,
    required this.productId,
    required this.warehouseId,
    required this.movementType,
    required this.quantity,
    required this.movementDate,
    this.purchaseOrderId,
    this.salesOrderId,
    this.manualEntryReason,
    this.notes,
  });

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) =>
      InventoryMovementModel(
        id: json["id"] ?? 0,
        productId: json["productId"] ?? 0,
        warehouseId: json["warehouseId"] ?? 0,
        movementType: json["movementType"] ?? '',
        quantity: json["quantity"] ?? 0,
        movementDate: DateTime.parse(json["movementDate"] ?? DateTime.now().toIso8601String()),
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
        if (purchaseOrderId != null) "purchaseOrderId": purchaseOrderId,
        if (salesOrderId != null) "salesOrderId": salesOrderId,
        if (manualEntryReason != null) "manualEntryReason": manualEntryReason,
        if (notes != null) "notes": notes,
      };
}
