import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/sales_tax_provider.dart';
import 'package:p_a_jewerly/models/sales_tax_detail_model.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class SalesTaxScreen extends StatefulWidget {
  const SalesTaxScreen({super.key});

  @override
  State<SalesTaxScreen> createState() => _SalesTaxScreenState();
}

class _SalesTaxScreenState extends State<SalesTaxScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taxTypeController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _salesOrderIdController = TextEditingController();
  int? _editingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesTaxProvider>().fetchSalesTaxes();
    });
  }

  @override
  void dispose() {
    _taxTypeController.dispose();
    _taxAmountController.dispose();
    _salesOrderIdController.dispose();
    super.dispose();
  }

  void _openDialog({SalesTaxDetailModel? tax}) {
    _editingId = tax?.id;
    _salesOrderIdController.text = tax?.salesOrderId?.toString() ?? '';
    _taxTypeController.text = tax?.taxType ?? '';
    _taxAmountController.text = tax?.taxAmount?.toString() ?? '';
    showDialog(context: context, builder: (_) => _buildDialog(tax), barrierDismissible: false);
  }

  Widget _buildDialog(SalesTaxDetailModel? tax) {
    return AlertDialog(
      title: Text(tax == null ? 'Add Sales Tax' : 'Edit Sales Tax'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _salesOrderIdController,
                decoration: const InputDecoration(
                  labelText: 'Sales Order ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxTypeController,
                decoration: const InputDecoration(
                  labelText: 'Tax Type',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., VAT, Sales Tax, GST',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxAmountController,
                decoration: const InputDecoration(
                  labelText: 'Tax Amount',
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
          onPressed: _saveSalesTax,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveSalesTax() async {
    if (!_formKey.currentState!.validate()) return;

    final tax = SalesTaxDetailModel(
      id: _editingId ?? 0,
      salesOrderId: int.tryParse(_salesOrderIdController.text.trim()),
      taxType: _taxTypeController.text.trim(),
      taxAmount: double.tryParse(_taxAmountController.text.trim()) ?? 0,
    );

    final provider = context.read<SalesTaxProvider>();
    bool success;

    if (_editingId == null) {
      success = await provider.createSalesTax(tax);
    } else {
      success = await provider.updateSalesTax(tax);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        success
            ? successSnackBar('Sales tax ${_editingId == null ? 'created' : 'updated'}')
            : errorSnackBar(provider.error ?? 'Operation failed'),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Sales Tax'),
        content: const Text('Are you sure you want to delete this sales tax entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SalesTaxProvider>().deleteSalesTax(id);
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
        title: const Text('Sales Tax'),
        backgroundColor: Colors.amber[700],
      ),
      body: Consumer<SalesTaxProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.salesTaxes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.fetchSalesTaxes(),
            );
          }
          if (provider.salesTaxes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No sales tax entries', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.salesTaxes.length,
            itemBuilder: (context, index) {
              final tax = provider.salesTaxes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: const Icon(Icons.percent, color: Colors.red),
                  ),
                  title: Text(tax.taxType ?? 'Tax ${tax.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sales Order ID: ${tax.salesOrderId ?? 'N/A'}'),
                      Text('Amount: \$${tax.taxAmount ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openDialog(tax: tax),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(tax.id),
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
        label: const Text('New Tax'),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}
