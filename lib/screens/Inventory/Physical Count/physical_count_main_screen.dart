import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p_a_jewerly/providers/inventory_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/models/product_model.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class PhysicalCountSession {
  final String id;
  final int warehouseId;
  final String warehouseName;
  final DateTime countDate;
  String status;
  List<PhysicalCountItem> items;

  PhysicalCountSession({
    required this.id,
    required this.warehouseId,
    required this.warehouseName,
    required this.countDate,
    required this.status,
    required this.items,
  });

  double get completionPercentage => items.isEmpty ? 0 : (items.where((i) => i.counted).length / items.length) * 100;
  int get countedCount => items.where((i) => i.counted).length;
  int get varianceCount => items.where((i) => i.variance != null && i.variance! != 0).length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'warehouseId': warehouseId,
    'warehouseName': warehouseName,
    'countDate': countDate.toIso8601String(),
    'status': status,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory PhysicalCountSession.fromJson(Map<String, dynamic> json) => PhysicalCountSession(
    id: json['id'],
    warehouseId: json['warehouseId'],
    warehouseName: json['warehouseName'],
    countDate: DateTime.parse(json['countDate']),
    status: json['status'],
    items: (json['items'] as List).map((i) => PhysicalCountItem.fromJson(i)).toList(),
  );
}

class PhysicalCountItem {
  final int? inventoryId; // null for custom items
  final int productId;
  String productName;
  final int systemQuantity;
  int? countedQuantity;
  int? variance;
  bool counted;
  String? notes;
  final bool isCustom; // true if added manually

  PhysicalCountItem({
    this.inventoryId,
    required this.productId,
    required this.productName,
    required this.systemQuantity,
    this.countedQuantity,
    this.variance,
    this.counted = false,
    this.notes,
    this.isCustom = false,
  });

  void calculateVariance() {
    if (countedQuantity != null) {
      variance = countedQuantity! - systemQuantity;
      counted = true;
    }
  }

  Map<String, dynamic> toJson() => {
    'inventoryId': inventoryId,
    'productId': productId,
    'productName': productName,
    'systemQuantity': systemQuantity,
    'countedQuantity': countedQuantity,
    'variance': variance,
    'counted': counted,
    'notes': notes,
    'isCustom': isCustom,
  };

  factory PhysicalCountItem.fromJson(Map<String, dynamic> json) => PhysicalCountItem(
    inventoryId: json['inventoryId'],
    productId: json['productId'],
    productName: json['productName'],
    systemQuantity: json['systemQuantity'],
    countedQuantity: json['countedQuantity'],
    variance: json['variance'],
    counted: json['counted'],
    notes: json['notes'],
    isCustom: json['isCustom'] ?? false,
  );
}

class PhysicalCountMainScreen extends StatefulWidget {
  const PhysicalCountMainScreen({super.key});

  @override
  State<PhysicalCountMainScreen> createState() => _PhysicalCountMainScreenState();
}

class _PhysicalCountMainScreenState extends State<PhysicalCountMainScreen> {
  PhysicalCountSession? _currentSession;
  bool _isLoading = false;
  List<PhysicalCountSession> _savedSessions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().fetchWarehouses();
      context.read<ProductProvider>().fetchProducts();
      context.read<InventoryProvider>().fetchInventory();
      _loadSavedSessions();
    });
  }

  Future<void> _loadSavedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList('physical_count_sessions') ?? [];
    setState(() {
      _savedSessions = sessionsJson
          .map((s) => PhysicalCountSession.fromJson(jsonDecode(s)))
          .where((s) => s.status == 'In Progress')
          .toList();
    });
  }

  Future<void> _saveSessionsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = _savedSessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('physical_count_sessions', sessionsJson);
  }

  void _startNewCount() {
    final warehouses = context.read<WarehouseProvider>().warehouses;
    if (warehouses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('No warehouses available. Add warehouses first.'),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Warehouse',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: warehouses.length,
                itemBuilder: (context, index) {
                  final warehouse = warehouses[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.warehouse, color: AppTheme.primaryGold),
                    ),
                    title: Text(warehouse.name ?? 'Warehouse ${warehouse.id}'),
                    subtitle: Text('ID: ${warehouse.id}'),
                    onTap: () {
                      Navigator.pop(context);
                      _initializeCountSession(warehouse.id!, warehouse.name ?? 'Warehouse ${warehouse.id}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _initializeCountSession(int warehouseId, String warehouseName) {
    final inventory = context.read<InventoryProvider>().inventory
        .where((i) => i.warehouseId == warehouseId)
        .toList();

    final products = context.read<ProductProvider>().products;

    final session = PhysicalCountSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      countDate: DateTime.now(),
      status: 'In Progress',
      items: inventory.map((inv) {
        final product = products.firstWhere(
          (p) => p.id == inv.productId,
          orElse: () => ProductModel(id: inv.productId ?? 0, description: 'Product ${inv.productId}'),
        );
        return PhysicalCountItem(
          inventoryId: inv.id,
          productId: inv.productId ?? 0,
          productName: product.description ?? 'Product ${inv.productId}',
          systemQuantity: inv.quantity ?? 0,
        );
      }).toList(),
    );

    setState(() {
      _currentSession = session;
      _savedSessions.add(session);
    });
    _saveSessionsToStorage();

    ScaffoldMessenger.of(context).showSnackBar(
      successSnackBar('Started counting ${session.items.length} items in $warehouseName'),
    );
  }

  void _addCustomItem() {
    if (_currentSession == null) return;

    final products = context.read<ProductProvider>().products.where((p) {
      // Filter out products already in the session
      return !_currentSession!.items.any((i) => i.productId == p.id);
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Custom Item',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (products.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No more products available to add'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                        child: Icon(Icons.diamond, color: AppTheme.primaryGold),
                      ),
                      title: Text(product.description ?? 'Product ${product.id}'),
                      subtitle: Text('ID: ${product.id}'),
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomItemCountDialog(product);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCustomItemCountDialog(ProductModel product) {
    final countController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Custom Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.description ?? 'Product ${product.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Physical Count',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.numbers),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.note),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(countController.text) ?? 0;
              if (count > 0) {
                setState(() {
                  _currentSession!.items.add(PhysicalCountItem(
                    inventoryId: null,
                    productId: product.id!,
                    productName: product.description ?? 'Product ${product.id}',
                    systemQuantity: 0, // Custom items have 0 system qty
                    countedQuantity: count,
                    notes: notesController.text.trim(),
                    isCustom: true,
                  ));
                  _currentSession!.items.last.calculateVariance();
                });
                _saveSessionsToStorage();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  successSnackBar('${product.description} added to count'),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _recordCount(PhysicalCountItem item, int quantity, String notes) {
    setState(() {
      final sessionItem = _currentSession!.items.firstWhere(
        (i) => i.inventoryId == item.inventoryId && i.productId == item.productId,
      );
      sessionItem.countedQuantity = quantity;
      sessionItem.notes = notes.isEmpty ? null : notes;
      sessionItem.calculateVariance();
    });
    _saveSessionsToStorage();
  }

  void _deleteItem(PhysicalCountItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Remove "${item.productName}" from this count?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentSession!.items.removeWhere(
                  (i) => i.inventoryId == item.inventoryId && i.productId == item.productId,
                );
              });
              _saveSessionsToStorage();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeCount() async {
    if (_currentSession == null) return;

    final uncountedItems = _currentSession!.items.where((i) => !i.counted).length;

    if (uncountedItems > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Incomplete Count'),
          content: Text('You have $uncountedItems items that haven\'t been counted yet. Are you sure you want to complete?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue Counting'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Complete Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    await _finalizeCount();
  }

  Future<void> _finalizeCount() async {
    if (_currentSession == null) return;

    setState(() => _isLoading = true);

    try {
      final adjustments = _currentSession!.items.where(
        (i) => i.variance != null && i.variance! != 0,
      ).toList();

      // Create inventory movements for each variance
      final api = ApiService();
      final inventoryProvider = context.read<InventoryProvider>();

      for (final item in adjustments) {
        try {
          // Create inventory movement
          await api.post('/InventoryMovement', body: {
            'inventoryId': item.inventoryId,
            'productId': item.productId,
            'warehouseId': _currentSession!.warehouseId,
            'movementType': 'Adjustment',
            'quantity': item.variance,
            'reference': 'Physical Count ${_currentSession!.id}',
            'notes': item.notes ?? 'Variance from physical count',
            'movementDate': DateTime.now().toIso8601String(),
          });

          // Also update the inventory quantity directly
          if (item.inventoryId != null) {
            await api.put(
              '/Inventory/UpdateQuantity',
              body: {
                'productId': item.productId,
                'warehouseId': _currentSession!.warehouseId,
                'quantityChange': item.variance,
              },
            );
          }
        } catch (e) {
          debugPrint('Error creating movement for item ${item.productId}: $e');
        }
      }

      // Refresh inventory
      await inventoryProvider.fetchInventory();

      // Update session status
      setState(() {
        _currentSession!.status = 'Completed';
        _savedSessions.removeWhere((s) => s.id == _currentSession!.id);
      });
      await _saveSessionsToStorage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          successSnackBar('Physical count completed! ${adjustments.length} adjustments recorded.'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          errorSnackBar('Error completing count: $e'),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelCount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Physical Count'),
        content: const Text('Are you sure? All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _savedSessions.removeWhere((s) => s.id == _currentSession!.id);
                _currentSession = null;
              });
              await _saveSessionsToStorage();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Physical count cancelled')),
                );
              }
            },
            child: const Text('Cancel Count', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCountDialog(PhysicalCountItem item) {
    final countController = TextEditingController(text: item.countedQuantity?.toString() ?? '');
    final notesController = TextEditingController(text: item.notes ?? '');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final variance = (int.tryParse(countController.text) ?? 0) - item.systemQuantity;

          return AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text(item.productName, overflow: TextOverflow.ellipsis)),
                if (item.isCustom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Custom', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: AppTheme.cream,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('System', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                item.systemQuantity.toString(),
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: AppTheme.lightGold.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('Physical', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: countController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (countController.text.isNotEmpty)
                  Card(
                    color: variance > 0
                        ? Colors.green[50]
                        : (variance < 0 ? Colors.red[50] : Colors.grey[100]),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            variance > 0
                                ? Icons.arrow_upward
                                : (variance < 0 ? Icons.arrow_downward : Icons.check),
                            color: variance > 0
                                ? Colors.green
                                : (variance < 0 ? Colors.red : Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Variance: ${variance > 0 ? '+' : ''}$variance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: variance > 0
                                  ? Colors.green
                                  : (variance < 0 ? Colors.red : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              if (item.counted)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _recordCount(item, 0, '');
                  },
                  child: const Text('Clear'),
                ),
              if (!item.isCustom)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteItem(item);
                  },
                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final count = int.tryParse(countController.text);
                  if (count == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      errorSnackBar('Please enter a valid quantity'),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _recordCount(item, count, notesController.text.trim());
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _printCountSheet() {
    if (_currentSession == null) return;

    final items = _currentSession!.items;
    final buffer = StringBuffer();

    buffer.writeln('PHYSICAL COUNT SHEET');
    buffer.writeln('====================');
    buffer.writeln('Warehouse: ${_currentSession!.warehouseName}');
    buffer.writeln('Date: ${_currentSession!.countDate.toString().split('.')[0]}');
    buffer.writeln('Session ID: ${_currentSession!.id}');
    buffer.writeln('');
    buffer.writeln('-' * 60);
    buffer.writeln('${'#'.padRight(4)} ${'Product'.padRight(35)} ${'System Qty'.padRight(10)} Counted');
    buffer.writeln('-' * 60);

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final name = item.productName.length > 33
          ? '${item.productName.substring(0, 30)}...'
          : item.productName;
      buffer.writeln(
        '${(i + 1).toString().padRight(4)} ${name.padRight(35)} ${item.systemQuantity.toString().padRight(10)} ${item.counted ? item.countedQuantity.toString() : ''}',
      );
    }

    buffer.writeln('-' * 60);
    buffer.writeln('Total Items: ${items.length}');
    buffer.writeln('Counted: ${_currentSession!.countedCount}');
    buffer.writeln('Remaining: ${items.length - _currentSession!.countedCount}');
    buffer.writeln('');
    buffer.writeln('Signature: ________________________');
    buffer.writeln('Notes: ____________________________');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Count Sheet'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Preview:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  buffer.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                successSnackBar('Count sheet copied to clipboard'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Physical Count'),
        backgroundColor: AppTheme.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentSession != null) ...[
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printCountSheet,
              tooltip: 'Print Count Sheet',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addCustomItem,
              tooltip: 'Add Custom Item',
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelCount,
              tooltip: 'Cancel Count',
            ),
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _isLoading ? null : _completeCount,
              tooltip: 'Complete Count',
            ),
          ],
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Completing count...',
        child: _currentSession == null
            ? _buildNoSessionView()
            : _buildCountView(),
      ),
    );
  }

  Widget _buildNoSessionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.deepPurple.withOpacity(0.1), AppTheme.mediumPurple.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2,
              size: 80,
              color: AppTheme.deepPurple,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Physical Inventory Count',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Verify physical stock matches system records',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startNewCount,
              icon: const Icon(Icons.add),
              label: const Text('Start New Count'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_savedSessions.isNotEmpty) ...[
            const SizedBox(height: 40),
            Row(
              children: [
                const Icon(Icons.history, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'In Progress (${_savedSessions.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._savedSessions.map((session) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                  child: Icon(Icons.pending, color: AppTheme.primaryGold),
                ),
                title: Text('${session.warehouseName} - ${session.items.length} items'),
                subtitle: Text(
                  'Started ${_formatDate(session.countDate)} - ${session.completionPercentage.toStringAsFixed(0)}% complete',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() => _currentSession = session);
                },
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildCountView() {
    final items = _currentSession!.items;
    final filteredItems = items.where((item) {
      // Simple filter - just return all items, user can scroll
      return true;
    }).toList();

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Total', items.length.toString(), Icons.inventory_2),
                  _buildStatColumn('Counted', _currentSession!.countedCount.toString(), Icons.check_circle),
                  _buildStatColumn('Variance', _currentSession!.varianceCount.toString(), Icons.warning),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _currentSession!.completionPercentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentSession!.completionPercentage.toStringAsFixed(1)}% Complete',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _currentSession!.warehouseName,
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        // Items list
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No items in this count',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: item.counted
                            ? BorderSide(color: Colors.green.withOpacity(0.3))
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () => _showCountDialog(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: item.counted
                                      ? (item.variance != null && item.variance! != 0
                                          ? Colors.orange[100]
                                          : Colors.green[100])
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.counted
                                      ? (item.variance != null && item.variance! != 0
                                          ? Icons.warning
                                          : Icons.check)
                                      : Icons.edit,
                                  color: item.counted
                                      ? (item.variance != null && item.variance! != 0
                                          ? Colors.orange
                                          : Colors.green)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.productName,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (item.isCustom)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGold.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text('Custom', style: TextStyle(fontSize: 10)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildInfoChip('System: ${item.systemQuantity}', Icons.computer),
                                        const SizedBox(width: 8),
                                        if (item.counted)
                                          _buildInfoChip(
                                            'Counted: ${item.countedQuantity}',
                                            item.variance != null && item.variance! != 0
                                                ? Icons.warning
                                                : Icons.check,
                                            color: item.variance != null && item.variance! != 0
                                                ? Colors.orange
                                                : Colors.green,
                                          )
                                        else
                                          _buildInfoChip('Not counted', Icons.hourglass_empty, color: Colors.grey),
                                      ],
                                    ),
                                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.notes!,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? Colors.grey),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color ?? Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
