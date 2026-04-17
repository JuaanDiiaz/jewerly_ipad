import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/payment_method_provider.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentMethodProvider>().fetchPaymentMethods();
    });
  }

  void _openDialog({int? id, String? description}) {
    showDialog(
      context: context,
      builder: (_) => FormDialog(
        title: id == null ? 'Add Payment Method' : 'Edit Payment Method',
        labelText: 'Description',
        initialValue: description,
        onSave: (value) async {
          final provider = context.read<PaymentMethodProvider>();
          bool success;
          if (id == null) {
            success = await provider.createPaymentMethod(value);
          } else {
            success = await provider.updatePaymentMethod(id, value);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              success
                  ? successSnackBar('Payment method ${id == null ? 'created' : 'updated'}')
                  : errorSnackBar(provider.error ?? 'Operation failed'),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(int id, String description) async {
    final confirmed = await confirmDelete(context, description, 'Payment Method');
    if (confirmed && mounted) {
      context.read<PaymentMethodProvider>().deletePaymentMethod(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D1B4E), Color(0xFF4A3266)],
            ),
          ),
        ),
      ),
      body: Consumer<PaymentMethodProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.paymentMethods.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  ElevatedButton(
                    onPressed: () => provider.fetchPaymentMethods(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.paymentMethods.isEmpty) {
            return const EmptyState(
              icon: Icons.payment_outlined,
              title: 'No payment methods',
              subtitle: 'Tap + to add a payment method',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.paymentMethods.length,
            itemBuilder: (context, index) {
              final method = provider.paymentMethods[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.credit_card, color: Colors.green),
                  ),
                  title: Text(method.description ?? 'Payment Method ${method.id}'),
                  subtitle: Text('ID: ${method.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openDialog(id: method.id, description: method.description),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(method.id, method.description ?? ''),
                        color: Colors.red,
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
        label: const Text('New Method'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
    );
  }
}
