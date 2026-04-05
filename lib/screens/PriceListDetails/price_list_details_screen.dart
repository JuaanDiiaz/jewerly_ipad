import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/price_list_detail_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/models/price_list_detail_model.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class PriceListDetailsScreen extends StatefulWidget {
  const PriceListDetailsScreen({super.key});

  @override
  State<PriceListDetailsScreen> createState() => _PriceListDetailsScreenState();
}

class _PriceListDetailsScreenState extends State<PriceListDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  int? _editingId;
  int? _selectedPriceListId;
  int? _selectedProductId;
  DateTime? _validFrom;
  DateTime? _validTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PriceListDetailProvider>().fetchPriceListDetails();
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _openDialog({PriceListDetailModel? detail}) {
    _editingId = detail?.id;
    _selectedPriceListId = detail?.priceListId;
    _selectedProductId = detail?.productId;
    _priceController.text = detail?.price?.toString() ?? '';
    _validFrom = detail?.validFrom;
    _validTo = detail?.validTo;
    showDialog(context: context, builder: (_) => _buildDialog(detail), barrierDismissible: false);
  }

  Future<void> _selectDate(DateTime? currentDate, Function(DateTime) onDateSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => onDateSelected(picked));
    }
  }

  Widget _buildDialog(PriceListDetailModel? detail) {
    final products = context.watch<ProductProvider>().products;
    return AlertDialog(
      title: Text(detail == null ? 'Add Price List Detail' : 'Edit Price List Detail'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _selectedPriceListId?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Price List ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _selectedPriceListId = int.tryParse(value),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                ),
                items: products.map((p) {
                  return DropdownMenuItem(value: p.id, child: Text(p.description ?? 'Product ${p.id}'));
                }).toList(),
                onChanged: (value) => _selectedProductId = value,
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('Valid From: ${_validFrom != null ? _validFrom!.toString().split(' ')[0] : 'Not set'}'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () => _selectDate(_validFrom, (d) => _validFrom = d),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('Valid To: ${_validTo != null ? _validTo!.toString().split(' ')[0] : 'Not set'}'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () => _selectDate(_validTo, (d) => _validTo = d),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePriceListDetail,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _savePriceListDetail() async {
    if (!_formKey.currentState!.validate()) return;

    final detail = PriceListDetailModel(
      id: _editingId ?? 0,
      priceListId: _selectedPriceListId,
      productId: _selectedProductId,
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      validFrom: _validFrom,
      validTo: _validTo,
    );

    final provider = context.read<PriceListDetailProvider>();
    bool success;

    if (_editingId == null) {
      success = await provider.createPriceListDetail(detail);
    } else {
      success = await provider.updatePriceListDetail(detail);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        success
            ? successSnackBar('Price list detail ${_editingId == null ? 'created' : 'updated'}')
            : errorSnackBar(provider.error ?? 'Operation failed'),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Price List Detail'),
        content: const Text('Are you sure you want to delete this price list detail?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PriceListDetailProvider>().deletePriceListDetail(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price List Details'),
        backgroundColor: Colors.amber[700],
      ),
      body: Consumer<PriceListDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.priceListDetails.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.fetchPriceListDetails(),
            );
          }
          if (provider.priceListDetails.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.price_check_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No price list details', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.priceListDetails.length,
            itemBuilder: (context, index) {
              final detail = provider.priceListDetails[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: const Icon(Icons.attach_money, color: Colors.orange),
                  ),
                  title: Text('Product ID: ${detail.productId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price List ID: ${detail.priceListId}'),
                      Text('Price: \$${detail.price ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      if (detail.validFrom != null) Text('Valid from: ${detail.validFrom!.toString().split(' ')[0]}'),
                      if (detail.validTo != null) Text('Valid to: ${detail.validTo!.toString().split(' ')[0]}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openDialog(detail: detail),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(detail.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Detail'),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}
