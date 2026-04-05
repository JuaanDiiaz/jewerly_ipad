import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/customer_payment_provider.dart';
import 'package:p_a_jewerly/providers/customer_provider.dart';
import 'package:p_a_jewerly/models/customer_payment_model.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class CustomerPaymentsScreen extends StatefulWidget {
  const CustomerPaymentsScreen({super.key});

  @override
  State<CustomerPaymentsScreen> createState() => _CustomerPaymentsScreenState();
}

class _CustomerPaymentsScreenState extends State<CustomerPaymentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedCustomerId;
  int? _selectedSalesOrderId;
  int? _selectedPaymentMethodId;
  DateTime? _paymentDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerPaymentProvider>().fetchPayments();
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _openDialog({CustomerPaymentModel? payment}) {
    _selectedCustomerId = payment?.customerId;
    _selectedSalesOrderId = payment?.salesOrderId;
    _selectedPaymentMethodId = payment?.paymentMethodId;
    _amountController.text = payment?.amount?.toString() ?? '';
    _notesController.text = payment?.notes ?? '';
    _paymentDate = payment?.paymentDate;
    showDialog(context: context, builder: (_) => _buildDialog(payment), barrierDismissible: false);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Widget _buildDialog(CustomerPaymentModel? payment) {
    final customers = context.watch<CustomerProvider>().customers;
    return AlertDialog(
      title: Text(payment == null ? 'Record Payment' : 'Edit Payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedCustomerId,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  border: OutlineInputBorder(),
                ),
                items: customers.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (value) => _selectedCustomerId = value,
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _selectedSalesOrderId?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Sales Order ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _selectedSalesOrderId = int.tryParse(value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _selectedPaymentMethodId?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Payment Method ID',
                  border: OutlineInputBorder(),
                  hintText: '1=Cash, 2=Credit Card, 3=Debit Card',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _selectedPaymentMethodId = int.tryParse(value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
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
                title: Text('Payment Date: ${_paymentDate != null ? _paymentDate!.toString().split(' ')[0] : 'Today'}'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _selectDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
          onPressed: _savePayment,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final payment = CustomerPaymentModel(
      id: 0,
      customerId: _selectedCustomerId,
      salesOrderId: _selectedSalesOrderId,
      paymentMethodId: _selectedPaymentMethodId,
      paymentDate: _paymentDate,
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      notes: _notesController.text.trim(),
    );

    final provider = context.read<CustomerPaymentProvider>();
    final success = await provider.createPayment(payment);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        success
            ? successSnackBar('Payment recorded successfully')
            : errorSnackBar(provider.error ?? 'Operation failed'),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CustomerPaymentProvider>().deletePayment(id);
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
        title: const Text('Customer Payments'),
        backgroundColor: Colors.amber[700],
      ),
      body: Consumer<CustomerPaymentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.fetchPayments(),
            );
          }
          if (provider.payments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No payments recorded', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.payments.length,
            itemBuilder: (context, index) {
              final payment = provider.payments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.attach_money, color: Colors.green),
                  ),
                  title: Text('Customer ID: ${payment.customerId ?? 'N/A'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount: \$${payment.amount ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      if (payment.paymentDate != null) Text('Date: ${payment.paymentDate!.toString().split(' ')[0]}'),
                      if (payment.notes != null && payment.notes!.isNotEmpty) Text('Notes: ${payment.notes}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(payment.id),
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
        label: const Text('Record Payment'),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}
