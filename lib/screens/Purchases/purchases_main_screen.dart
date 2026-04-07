import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:p_a_jewerly/providers/purchase_order_provider.dart';
import 'package:p_a_jewerly/providers/supplier_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/product_image_provider.dart';
import 'package:p_a_jewerly/providers/supplier_product_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/providers/inventory_provider.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/purchase_order_header_model.dart';
import 'package:p_a_jewerly/models/purchase_order_detail_model.dart';
import 'package:p_a_jewerly/models/supplier_model.dart';
import 'package:p_a_jewerly/models/product_model.dart';
import 'package:p_a_jewerly/models/supplier_product_model.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class PurchasesMainScreen extends StatefulWidget {
  const PurchasesMainScreen({super.key});

  @override
  State<PurchasesMainScreen> createState() => _PurchasesMainScreenState();
}

class _PurchasesMainScreenState extends State<PurchasesMainScreen> {
  String _statusFilter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseOrderProvider>().fetchOrders();
      context.read<SupplierProvider>().fetchSuppliers();
      context.read<ProductProvider>().fetchProducts();
      context.read<ProductImageProvider>().fetchAllImages();
      context.read<SupplierProductProvider>().fetchSupplierProducts();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getSupplierName(int? supplierId, List<SupplierModel> suppliers) {
    if (supplierId == null) return 'Unknown';
    try {
      final supplier = suppliers.firstWhere((s) => s.id == supplierId);
      return supplier.name ?? 'Supplier #$supplierId';
    } catch (_) {
      return 'Supplier #$supplierId';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'pending':
        return Colors.orange;
      case 'in transit':
      case 'in_transit':
        return Colors.blue;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.subtleText;
    }
  }

  PdfColor _getStatusPdfColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return PdfColor.fromInt(0xFF4CAF50);
      case 'pending':
        return PdfColor.fromInt(0xFFFF9800);
      case 'in transit':
      case 'in_transit':
        return PdfColor.fromInt(0xFF2196F3);
      case 'cancelled':
        return PdfColor.fromInt(0xFFE53935);
      default:
        return PdfColor.fromInt(0xFF9E9E9E);
    }
  }

  void _showCreateOrderDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateOrderSheet(
        onOrderCreated: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            successSnackBar('Purchase order created successfully'),
          );
        },
      ),
    );
  }

  void _showSupplierProductsDialog(SupplierModel supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SupplierProductsSheet(supplier: supplier),
    );
  }

  void _showOrderDetails(PurchaseOrderHeaderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }

  Future<void> _generatePdf(PurchaseOrderHeaderModel order) async {
    final supplierProvider = context.read<SupplierProvider>();
    final purchaseProvider = context.read<PurchaseOrderProvider>();
    final productProvider = context.read<ProductProvider>();
    final supplierProductProvider = context.read<SupplierProductProvider>();

    final supplier = supplierProvider.suppliers.firstWhere(
      (s) => s.id == order.supplierId,
      orElse: () => SupplierModel(id: 0, name: 'Unknown'),
    );

    // Fetch order details
    await purchaseProvider.fetchOrderDetails(order.id);
    final details = purchaseProvider.orderDetails;

    final pdf = pw.Document();

    // Load logo
    final logoBytes = await rootBundle.load('assets/JewelryLogo.jpg');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logo, width: 80, height: 80),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'PURCHASE ORDER',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFFD4AF37),
                      ),
                    ),
                    pw.Text('PO-${order.id.toString().padLeft(6, '0')}'),
                    pw.Text(
                      DateFormat('MMMM dd, yyyy').format(order.orderDate ?? DateTime.now()),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xFFD4AF37)),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SUPPLIER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text(supplier.name ?? 'N/A', style: const pw.TextStyle(fontSize: 14)),
                        if (supplier.clientNumber != null)
                          pw.Text('Client #: ${supplier.clientNumber}'),
                        if (supplier.shipVia != null)
                          pw.Text('Ship via: ${supplier.shipVia}'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('STATUS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: _getStatusPdfColor(order.status),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                          ),
                          child: pw.Text(
                            order.status?.toUpperCase() ?? 'PENDING',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFD4AF37)),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2D1B4E)),
                children: [
                  _buildTableHeader('#'),
                  _buildTableHeader('Product'),
                  _buildTableHeader('Art Code'),
                  _buildTableHeader('Qty'),
                  _buildTableHeader('Unit Price'),
                  _buildTableHeader('Total'),
                ],
              ),
              ...details.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final detail = entry.value;
                final product = productProvider.products.firstWhere(
                  (p) => p.id == detail.productId,
                  orElse: () => ProductModel(id: 0, description: 'Unknown'),
                );
                // Find supplier product code
                final supplierProduct = supplierProductProvider.supplierProducts.firstWhere(
                  (sp) => sp.supplierId == order.supplierId && sp.productId == detail.productId,
                  orElse: () => SupplierProductModel(id: 0),
                );
                final supplierCode = supplierProduct.artCode ?? supplierProduct.styleCode ?? '-';
                return pw.TableRow(
                  children: [
                    _buildTableCell(index.toString()),
                    _buildTableCell(product.description ?? 'Product #${detail.productId}'),
                    _buildTableCell(supplierCode),
                    _buildTableCell(detail.quantity.toString()),
                    _buildTableCell('\$${(detail.unitPrice ?? 0).toStringAsFixed(2)}'),
                    _buildTableCell('\$${(detail.total ?? 0).toStringAsFixed(2)}'),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF5E6C8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('TOTAL: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '\$${(order.total ?? 0).toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('NOTES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(order.notes!),
            ),
          ],
        ],
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('P&A Jewelry - Purchase Order #${order.id}'),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text),
    );
  }

  List<PurchaseOrderHeaderModel> _filterOrders(List<PurchaseOrderHeaderModel> orders) {
    var filtered = orders;

    if (_statusFilter != 'All') {
      filtered = filtered.where((o) => o.status?.toLowerCase() == _statusFilter.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((o) {
        return o.id.toString().contains(_searchQuery) ||
            o.status?.toLowerCase().contains(_searchQuery) == true ||
            o.notes?.toLowerCase().contains(_searchQuery) == true;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with search and filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepPurple.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.cream,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Status')),
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'In Transit', child: Text('In Transit')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value ?? 'All'),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: Consumer2<PurchaseOrderProvider, SupplierProvider>(
              builder: (context, orderProvider, supplierProvider, _) {
                if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
                }
                if (orderProvider.error != null) {
                  return AppErrorWidget(
                    message: orderProvider.error!,
                    onRetry: () => orderProvider.fetchOrders(),
                  );
                }
                if (orderProvider.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.primaryGold.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No purchase orders', style: TextStyle(fontSize: 18, color: AppTheme.subtleText)),
                        const SizedBox(height: 8),
                        Text('Create your first purchase order', style: TextStyle(color: AppTheme.subtleText)),
                      ],
                    ),
                  );
                }

                final filteredOrders = _filterOrders(orderProvider.orders);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppTheme.subtleText.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No orders match your search', style: TextStyle(color: AppTheme.subtleText)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final supplierName = _getSupplierName(order.supplierId, supplierProvider.suppliers);
                    final statusColor = _getStatusColor(order.status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppTheme.goldBorderDecoration(),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.shopping_bag_outlined, color: statusColor),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'PO-${order.id.toString().padLeft(6, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status ?? 'Pending',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(supplierName, style: TextStyle(color: AppTheme.subtleText)),
                            Text(
                              'Order Date: ${order.orderDate != null ? DateFormat('MMM dd, yyyy').format(order.orderDate!) : 'N/A'}',
                              style: TextStyle(color: AppTheme.subtleText, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$${(order.total ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.print),
                              onPressed: () => _generatePdf(order),
                              tooltip: 'Print PDF',
                              color: AppTheme.primaryGold,
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _showOrderDetails(order),
                              tooltip: 'View Details',
                              color: AppTheme.mediumPurple,
                            ),
                          ],
                        ),
                        onTap: () => _showOrderDetails(order),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOrderDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.darkText,
      ),
    );
  }
}

// Create Order Sheet - Shows only products linked to selected supplier
class _CreateOrderSheet extends StatefulWidget {
  final VoidCallback onOrderCreated;

  const _CreateOrderSheet({required this.onOrderCreated});

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _OrderItem {
  int? productId;
  int quantity = 1;
  double unitPrice = 0;

  double get total => quantity * unitPrice;
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedSupplierId;
  DateTime _orderDate = DateTime.now();
  String _status = 'Pending';
  String _notes = '';
  final List<_OrderItem> _items = [];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.gradientDecoration(radius: 12),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGold, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Create Purchase Order',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Supplier Selection
                  Consumer2<SupplierProvider, SupplierProductProvider>(
                    builder: (context, supplierProvider, spProvider, _) {
                      return Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _selectedSupplierId,
                              decoration: InputDecoration(
                                labelText: 'Supplier',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.store),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Select Supplier')),
                                ...supplierProvider.suppliers.map((s) {
                                  return DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name ?? 'Supplier ${s.id}'),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSupplierId = value;
                                  _items.clear(); // Clear items when supplier changes
                                });
                              },
                              validator: (value) {
                                if (value == null) return 'Please select a supplier';
                                return null;
                              },
                            ),
                          ),
                          if (_selectedSupplierId != null) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                final supplier = supplierProvider.suppliers.firstWhere(
                                  (s) => s.id == _selectedSupplierId,
                                  orElse: () => SupplierModel(id: 0, name: 'Unknown'),
                                );
                                _showManageSupplierProducts(supplier);
                              },
                              icon: const Icon(Icons.settings),
                              tooltip: 'Manage Products',
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.cream,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Show available products count for selected supplier
                  if (_selectedSupplierId != null)
                    Consumer<SupplierProductProvider>(
                      builder: (context, spProvider, _) {
                        final supplierProducts = spProvider.supplierProducts
                            .where((sp) => sp.supplierId == _selectedSupplierId)
                            .toList();
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: supplierProducts.isEmpty ? Colors.orange.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                supplierProducts.isEmpty ? Icons.warning : Icons.check_circle,
                                color: supplierProducts.isEmpty ? Colors.orange : AppTheme.success,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                supplierProducts.isEmpty
                                    ? 'No products linked to this supplier. Add products first.'
                                    : '${supplierProducts.length} products available for this supplier',
                                style: TextStyle(
                                  color: supplierProducts.isEmpty ? Colors.orange : AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Order Date
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _orderDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _orderDate = date);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Order Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('MMMM dd, yyyy').format(_orderDate)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.info_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'In Transit', child: Text('In Transit')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                    ],
                    onChanged: (value) => setState(() => _status = value ?? 'Pending'),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _notes = value,
                  ),
                  const SizedBox(height: 24),

                  // Order Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ElevatedButton.icon(
                        onPressed: _selectedSupplierId == null ? null : _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _selectedSupplierId == null
                              ? 'Select a supplier first'
                              : 'No items added. Click "Add Item" to add products.',
                          style: TextStyle(color: AppTheme.subtleText),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, index) => _buildItemCard(index),
                    ),
                  const SizedBox(height: 24),

                  // Total
                  if (_items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGold.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Text(
                            '\$${_calculateTotal().toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.success),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppTheme.subtleText),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saveOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Create Order'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showManageSupplierProducts(SupplierModel supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SupplierProductsSheet(supplier: supplier),
    );
  }

  void _addItem() {
    // Check if supplier has products
    final spProvider = context.read<SupplierProductProvider>();
    final supplierProducts = spProvider.supplierProducts
        .where((sp) => sp.supplierId == _selectedSupplierId)
        .toList();

    if (supplierProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('No products linked to this supplier. Add products first.'),
      );
      return;
    }

    setState(() {
      _items.add(_OrderItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    final spProvider = context.read<SupplierProductProvider>();

    // Get only products linked to this supplier
    final supplierProducts = spProvider.supplierProducts
        .where((sp) => sp.supplierId == _selectedSupplierId)
        .toList();

    final productProvider = context.read<ProductProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.goldBorderDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.delete, color: AppTheme.error),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              return DropdownButtonFormField<int>(
                value: item.productId,
                decoration: InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: supplierProducts.map((sp) {
                  final product = productProvider.products.firstWhere(
                    (p) => p.id == sp.productId,
                    orElse: () => ProductModel(id: sp.productId ?? 0, description: 'Unknown'),
                  );
                  final code = sp.artCode ?? sp.styleCode ?? '';
                  return DropdownMenuItem(
                    value: sp.productId,
                    child: Text('${product.description ?? 'Product'}${code.isNotEmpty ? ' ($code)' : ''}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    item.productId = value;
                    // Auto-fill price from supplier product
                    final sp = supplierProducts.firstWhere((sp) => sp.productId == value, orElse: () => SupplierProductModel(id: 0));
                    item.unitPrice = (sp.price ?? 0).toDouble();
                  });
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    item.quantity = int.tryParse(value) ?? 1;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.unitPrice > 0 ? item.unitPrice.toStringAsFixed(2) : '',
                  decoration: InputDecoration(
                    labelText: 'Unit Price',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    item.unitPrice = double.tryParse(value) ?? 0;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Subtotal: \$${item.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.success),
          ),
        ],
      ),
    );
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar('Please add at least one item'));
      return;
    }
    if (_items.any((item) => item.productId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar('Please select a product for all items'));
      return;
    }

    final orderProvider = context.read<PurchaseOrderProvider>();

    // Create header
    final order = PurchaseOrderHeaderModel(
      id: 0,
      supplierId: _selectedSupplierId,
      orderDate: _orderDate,
      status: _status,
      total: _calculateTotal(),
      notes: _notes,
    );

    final createdOrder = await orderProvider.createOrder(order);

    if (createdOrder != null && createdOrder.id > 0) {
      // Create details
      for (final item in _items) {
        if (item.productId != null) {
          await orderProvider.addOrderDetail(PurchaseOrderDetailModel(
            id: 0,
            purchaseOrderId: createdOrder.id,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            total: item.total,
          ));
        }
      }
      widget.onOrderCreated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(orderProvider.error ?? 'Failed to create order'),
      );
    }
  }
}

// Supplier Products Sheet - Manage products linked to supplier
class _SupplierProductsSheet extends StatefulWidget {
  final SupplierModel supplier;

  const _SupplierProductsSheet({required this.supplier});

  @override
  State<_SupplierProductsSheet> createState() => _SupplierProductsSheetState();
}

class _SupplierProductsSheetState extends State<_SupplierProductsSheet> {
  final _artCodeController = TextEditingController();
  final _styleCodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedProductId;

  @override
  void dispose() {
    _artCodeController.dispose();
    _styleCodeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.gradientDecoration(radius: 12),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGold, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.supplier.name ?? 'Unknown Supplier',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage Products',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Currently Linked Products
                const Text('Linked Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Consumer<SupplierProductProvider>(
                  builder: (context, spProvider, _) {
                    final linkedProducts = spProvider.supplierProducts
                        .where((sp) => sp.supplierId == widget.supplier.id)
                        .toList();

                    if (linkedProducts.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('No products linked yet', style: TextStyle(color: AppTheme.subtleText)),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: linkedProducts.length,
                      itemBuilder: (context, index) {
                        final sp = linkedProducts[index];
                        return Consumer<ProductProvider>(
                          builder: (context, productProvider, _) {
                            final product = productProvider.products.firstWhere(
                              (p) => p.id == sp.productId,
                              orElse: () => ProductModel(id: 0, description: 'Unknown'),
                            );
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: AppTheme.goldBorderDecoration(),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGold.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.diamond_outlined, color: AppTheme.primaryGold),
                                  ),
                                ),
                                title: Text(product.description ?? 'Product #${sp.productId}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sp.artCode != null) Text('Art Code: ${sp.artCode}'),
                                    if (sp.styleCode != null) Text('Style: ${sp.styleCode}'),
                                    if (sp.price != null) Text('Price: \$${sp.price}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: AppTheme.error),
                                  onPressed: () => _deleteSupplierProduct(sp),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Add New Product
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Product to Supplier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Consumer<ProductProvider>(
                        builder: (context, productProvider, _) {
                          final spProvider = context.read<SupplierProductProvider>();
                          final linkedProductIds = spProvider.supplierProducts
                              .where((sp) => sp.supplierId == widget.supplier.id)
                              .map((sp) => sp.productId)
                              .toSet();

                          // Only show products NOT already linked
                          final availableProducts = productProvider.products
                              .where((p) => !linkedProductIds.contains(p.id))
                              .toList();

                          return DropdownButtonFormField<int>(
                            value: _selectedProductId,
                            decoration: InputDecoration(
                              labelText: 'Select Product',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Choose a product')),
                              ...availableProducts.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.description ?? 'Product ${p.id}'),
                                );
                              }),
                            ],
                            onChanged: (value) => setState(() => _selectedProductId = value),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _artCodeController,
                              decoration: InputDecoration(
                                labelText: 'Art Code',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _styleCodeController,
                              decoration: InputDecoration(
                                labelText: 'Style Code',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Supplier Price',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixText: '\$',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addProductToSupplier,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addProductToSupplier() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar('Please select a product'));
      return;
    }

    final spProvider = context.read<SupplierProductProvider>();
    final success = await spProvider.createSupplierProduct(SupplierProductModel(
      id: 0,
      supplierId: widget.supplier.id,
      productId: _selectedProductId,
      artCode: _artCodeController.text.trim().isNotEmpty ? _artCodeController.text.trim() : null,
      styleCode: _styleCodeController.text.trim().isNotEmpty ? _styleCodeController.text.trim() : null,
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      price: double.tryParse(_priceController.text),
    ));

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(successSnackBar('Product added to supplier'));
      // Clear form
      setState(() {
        _selectedProductId = null;
        _artCodeController.clear();
        _styleCodeController.clear();
        _priceController.clear();
        _descriptionController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(spProvider.error ?? 'Failed to add product'),
      );
    }
  }

  Future<void> _deleteSupplierProduct(SupplierProductModel sp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Product'),
        content: const Text('Are you sure you want to remove this product from the supplier?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final spProvider = context.read<SupplierProductProvider>();
      final success = await spProvider.deleteSupplierProduct(sp.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(successSnackBar('Product removed'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(errorSnackBar(spProvider.error ?? 'Failed to remove'));
      }
    }
  }
}

// Order Details Sheet - with editable status
class _OrderDetailsSheet extends StatefulWidget {
  final PurchaseOrderHeaderModel order;

  const _OrderDetailsSheet({required this.order});

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  late String _selectedStatus;
  late DateTime? _receptionDate;
  late String _notes;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status ?? 'Pending';
    _receptionDate = widget.order.receptionDate;
    _notes = widget.order.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.gradientDecoration(radius: 12),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: AppTheme.primaryGold, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purchase Order #${widget.order.id.toString().padLeft(6, '0')}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              DateFormat('MMMM dd, yyyy').format(widget.order.orderDate ?? DateTime.now()),
                              style: TextStyle(color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.white),
                        onPressed: () => _printOrder(context),
                        tooltip: 'Print PDF',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Edit Mode Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit Order' : 'Order Details',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: Icon(_isEditing ? Icons.close : Icons.edit),
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                      style: IconButton.styleFrom(
                        backgroundColor: _isEditing ? AppTheme.error.withOpacity(0.1) : AppTheme.primaryGold.withOpacity(0.1),
                      ),
                      color: _isEditing ? AppTheme.error : AppTheme.primaryGold,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Supplier (non-editable)
                Consumer<SupplierProvider>(
                  builder: (context, supplierProvider, _) {
                    final supplier = supplierProvider.suppliers.firstWhere(
                      (s) => s.id == widget.order.supplierId,
                      orElse: () => SupplierModel(id: 0, name: 'Unknown'),
                    );
                    return _buildInfoCard('Supplier', supplier.name ?? 'N/A');
                  },
                ),
                const SizedBox(height: 12),

                // Status (editable)
                if (_isEditing)
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.info_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'In Transit', child: Text('In Transit')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (value) => setState(() => _selectedStatus = value ?? 'Pending'),
                  )
                else
                  _buildInfoCard('Status', widget.order.status ?? 'Pending', _getStatusColor(widget.order.status)),
                const SizedBox(height: 12),

                // Reception Date (editable)
                if (_isEditing) ...[
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _receptionDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _receptionDate = date);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Reception Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _receptionDate != null
                            ? DateFormat('MMMM dd, yyyy').format(_receptionDate!)
                            : 'Not set',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (widget.order.receptionDate != null)
                  _buildInfoCard('Reception Date', DateFormat('MMMM dd, yyyy').format(widget.order.receptionDate!)),
                const SizedBox(height: 12),

                // Notes (editable)
                if (_isEditing)
                  TextFormField(
                    initialValue: _notes,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                    maxLines: 3,
                    onChanged: (value) => _notes = value,
                  )
                else if (widget.order.notes != null && widget.order.notes!.isNotEmpty)
                  _buildInfoCard('Notes', widget.order.notes!),
                const SizedBox(height: 12),

                // Total
                _buildInfoCard('Total', '\$${(widget.order.total ?? 0).toStringAsFixed(2)}'),
                const SizedBox(height: 24),

                // Save Button (only in edit mode)
                if (_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (_isEditing) const SizedBox(height: 12),

                // Order Items
                const Text('Order Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                Consumer<PurchaseOrderProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final details = provider.orderDetails
                        .where((d) => d.purchaseOrderId == widget.order.id)
                        .toList();

                    if (details.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('No items', style: TextStyle(color: AppTheme.subtleText)),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: details.length,
                      itemBuilder: (context, index) {
                        final detail = details[index];
                        return Consumer2<ProductProvider, SupplierProductProvider>(
                          builder: (context, productProvider, spProvider, _) {
                            final product = productProvider.products.firstWhere(
                              (p) => p.id == detail.productId,
                              orElse: () => ProductModel(id: 0, description: 'Unknown'),
                            );
                            final supplierProduct = spProvider.supplierProducts.firstWhere(
                              (sp) => sp.supplierId == widget.order.supplierId && sp.productId == detail.productId,
                              orElse: () => SupplierProductModel(id: 0),
                            );
                            final code = supplierProduct.artCode ?? supplierProduct.styleCode ?? '-';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: AppTheme.goldBorderDecoration(),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGold.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                title: Text(product.description ?? 'Product #${detail.productId}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (code != '-') Text('Code: $code', style: TextStyle(color: AppTheme.subtleText, fontSize: 12)),
                                    Text('Qty: ${detail.quantity} × \$${(detail.unitPrice ?? 0).toStringAsFixed(2)}'),
                                  ],
                                ),
                                trailing: Text(
                                  '\$${(detail.total ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: AppTheme.darkText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'pending':
        return Colors.orange;
      case 'in transit':
      case 'in_transit':
        return Colors.blue;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.subtleText;
    }
  }

  Widget _buildInfoCard(String label, String value, [Color? valueColor]) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.goldBorderDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }

  void _printOrder(BuildContext context) {
    // Find the parent state and call its _generatePdf method
    Navigator.pop(context);
    // Re-open to print
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final purchasesState = context.findAncestorStateOfType<_PurchasesMainScreenState>();
      if (purchasesState != null) {
        purchasesState._generatePdf(widget.order);
      }
    });
  }

  Future<void> _saveChanges() async {
    final orderProvider = context.read<PurchaseOrderProvider>();

    final updatedOrder = PurchaseOrderHeaderModel(
      id: widget.order.id,
      supplierId: widget.order.supplierId,
      orderDate: widget.order.orderDate,
      status: _selectedStatus,
      total: widget.order.total,
      receptionDate: _receptionDate,
      notes: _notes,
    );

    // Check if status is changing to Completed
    final wasNotCompleted = widget.order.status?.toLowerCase() != 'completed';
    final isNowCompleted = _selectedStatus?.toLowerCase() == 'completed';

    if (wasNotCompleted && isNowCompleted) {
      // Show warehouse selection dialog before completing
      final warehouseId = await _showWarehouseSelectionDialog();
      if (warehouseId == null) return; // User cancelled

      final success = await orderProvider.updateOrder(updatedOrder);
      if (success && mounted) {
        // Add items to inventory
        await _addItemsToInventory(warehouseId);
        ScaffoldMessenger.of(context).showSnackBar(successSnackBar('Order completed and inventory updated'));
        setState(() => _isEditing = false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          errorSnackBar(orderProvider.error ?? 'Failed to update order'),
        );
      }
    } else {
      final success = await orderProvider.updateOrder(updatedOrder);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(successSnackBar('Order updated successfully'));
        setState(() => _isEditing = false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          errorSnackBar(orderProvider.error ?? 'Failed to update order'),
        );
      }
    }
  }

  Future<int?> _showWarehouseSelectionDialog() async {
    final warehouseProvider = context.read<WarehouseProvider>();
    await warehouseProvider.fetchWarehouses();

    if (warehouseProvider.warehouses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          errorSnackBar('No warehouses available. Please add a warehouse first.'),
        );
      }
      return null;
    }

    int? selectedWarehouseId;
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Warehouse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select the warehouse where received items will be stored:'),
            const SizedBox(height: 16),
            ...warehouseProvider.warehouses.map((wh) => ListTile(
              leading: const Icon(Icons.warehouse),
              title: Text(wh.name ?? 'Warehouse ${wh.id}'),
              onTap: () => Navigator.pop(context, wh.id),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addItemsToInventory(int warehouseId) async {
    final orderProvider = context.read<PurchaseOrderProvider>();
    final apiService = ApiService();
    final details = orderProvider.orderDetails.where((d) => d.purchaseOrderId == widget.order.id).toList();

    for (final detail in details) {
      // Create inventory movement (IN movement for purchase)
      final movementData = {
        'productId': detail.productId,
        'warehouseId': warehouseId,
        'movementType': 'IN',
        'quantity': detail.quantity,
        'movementDate': DateTime.now().toIso8601String().split('T')[0],
        'purchaseOrderId': widget.order.id,
        'notes': 'Received from purchase order #${widget.order.id}',
      };
      await apiService.post('/InventoryMovement', body: movementData);
    }
  }
}