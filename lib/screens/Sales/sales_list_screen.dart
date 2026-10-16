import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:p_a_jewerly/providers/sales_provider.dart';
import 'package:p_a_jewerly/providers/customer_provider.dart';
import 'package:p_a_jewerly/providers/customer_payment_provider.dart';
import 'package:p_a_jewerly/providers/payment_method_provider.dart';
import 'package:p_a_jewerly/models/sales_order_header_model.dart';
import 'package:p_a_jewerly/models/customer_payment_model.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/utils/format.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';
import 'package:p_a_jewerly/widgets/paged_list_view.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  int? _expandedSaleId;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentFormKey = GlobalKey<FormState>();
  int? _selectedPaymentMethodId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<SalesProvider>().fetchSales();
      context.read<CustomerProvider>().fetchCustomers(fetchAll: true);
      context.read<CustomerPaymentProvider>().fetchPayments();
      await context.read<PaymentMethodProvider>().fetchPaymentMethods();
      if (mounted) {
        context.read<PaymentMethodProvider>().ensureMultiplePaymentsMethod();
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getCustomerName(int? customerId) {
    if (customerId == null) return 'Unknown';
    final customers = context.read<CustomerProvider>().customers;
    try {
      final customer = customers.firstWhere((c) => c.id == customerId);
      return customer.name;
    } catch (_) {
      return 'Customer #$customerId';
    }
  }

  String _getPaymentMethodName(int? methodId) {
    if (methodId == null) return 'Not specified';
    final methods = context.read<PaymentMethodProvider>().paymentMethods;
    try {
      final method = methods.firstWhere((m) => m.id == methodId);
      return method.description ?? 'Unknown';
    } catch (_) {
      return 'Method #$methodId';
    }
  }

  Color _getStatusColor(double paid, double total, bool isMultiple) {
    if (paid >= total) return AppTheme.success;
    if (paid > 0) return AppTheme.primaryGold;
    // Non-multiple payments are always considered paid at time of sale
    if (!isMultiple) return AppTheme.success;
    return AppTheme.error;
  }

  String _getStatusText(double paid, double total, bool isMultiple) {
    if (paid >= total) return 'Paid';
    if (paid > 0) return 'Partial';
    // Non-multiple payments are always considered paid at time of sale
    if (!isMultiple) return 'Paid';
    return 'Pending';
  }

  bool _isMultiplePayments(int? methodId) {
    if (methodId == null) return false;
    final methods = context.read<PaymentMethodProvider>().paymentMethods;
    try {
      final method = methods.firstWhere((m) => m.id == methodId);
      final desc = method.description?.toLowerCase() ?? '';
      return desc.contains('multiple') || desc.contains('varias') || desc.contains('parcial');
    } catch (_) {
      return false;
    }
  }

  void _showAddPaymentDialog(SalesOrderHeaderModel sale, double remaining) {
    _amountController.clear();
    _notesController.clear();
    _selectedPaymentMethodId = null;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Payment - Sale #${sale.id}'),
        // StatefulBuilder so the method dropdown's selection visibly updates
        // inside the dialog (the owner State's setState doesn't rebuild it).
        content: StatefulBuilder(
          builder: (dialogContext, setDialogState) => SingleChildScrollView(
            child: Form(
              key: _paymentFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGold.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '${formatCurrency(remaining)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<PaymentMethodProvider>(
                    builder: (context, pmProvider, _) {
                      return DropdownButtonFormField<int?>(
                        value: _selectedPaymentMethodId,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.credit_card, color: AppTheme.primaryGold),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Select method')),
                          ...pmProvider.paymentMethods.map((m) {
                            return DropdownMenuItem(value: m.id, child: Text(m.description ?? 'Method ${m.id}'));
                          }),
                        ],
                        onChanged: (value) => setDialogState(() => _selectedPaymentMethodId = value),
                        validator: (value) =>
                            value == null ? 'Please select a payment method' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (value == null || value.trim().isEmpty || amount == null || amount <= 0) {
                        return 'Enter an amount greater than zero';
                      }
                      // Block overpayment visibly instead of recording it silently.
                      if (amount > remaining + 0.009) {
                        return 'Exceeds the remaining balance (${formatCurrency(remaining)})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_paymentFormKey.currentState!.validate()) return;
              final amount = double.parse(_amountController.text.trim());

              final paymentProvider = context.read<CustomerPaymentProvider>();
              final paymentData = CustomerPaymentModel(
                id: 0, // Will be assigned by backend
                customerId: sale.customerId,
                salesOrderId: sale.id,
                paymentDate: DateTime.now(),
                amount: amount,
                paymentMethodId: _selectedPaymentMethodId,
                notes: _notesController.text.isNotEmpty ? _notesController.text : null,
              );

              final success = await paymentProvider.createPayment(paymentData);
              Navigator.pop(dialogContext);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  successSnackBar('Payment of ${formatCurrency(amount)} recorded'),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  errorSnackBar(paymentProvider.error ?? 'Failed to record payment'),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
            child: const Text('Add Payment'),
          ),
        ],
      ),
    );
  }

  List<SalesOrderHeaderModel> _filterSales(List<SalesOrderHeaderModel> sales) {
    if (_searchQuery.isEmpty) return sales;
    return sales.where((sale) {
      final customerName = _getCustomerName(sale.customerId).toLowerCase();
      final saleId = sale.id.toString();
      return customerName.contains(_searchQuery) || saleId.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        flexibleSpace: Container(
          decoration: AppTheme.gradientDecoration(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepPurple.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by customer or sale ID...',
                hintStyle: TextStyle(color: AppTheme.mutedText),
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryGold),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.mutedText),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.hairline,
              ),
            ),
          ),
          // Sales list
          Expanded(
            child: Consumer4<SalesProvider, CustomerProvider, CustomerPaymentProvider, PaymentMethodProvider>(
              builder: (context, salesProvider, customerProvider, paymentProvider, pmProvider, _) {
                if (salesProvider.isLoading && salesProvider.sales.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
                }

                // A failed fetch with stale rows keeps the list visible and
                // surfaces the failure as a banner instead of swallowing it.
                final Widget? errorBanner = salesProvider.error != null
                    ? ErrorBanner(
                        message: salesProvider.error!,
                        onRetry: () => salesProvider.fetchSales(),
                      )
                    : null;

                final filteredSales = _filterSales(salesProvider.sales);

                if (filteredSales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.primaryGold.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          salesProvider.sales.isEmpty ? 'No sales recorded' : 'No sales found',
                          style: TextStyle(fontSize: 18, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  );
                }

                Widget list = PagedListView(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSales.length,
                  hasMore: salesProvider.hasMore,
                  isLoadingMore: salesProvider.isLoadingMore,
                  onLoadMore: () => salesProvider.fetchSales(loadMore: true),
                  onRefresh: () => salesProvider.fetchSales(),
                  itemBuilder: (context, index) {
                    final sale = filteredSales[index];
                    final total = (sale.total as num?)?.toDouble() ?? 0;
                    final payments = paymentProvider.getPaymentsForSalesOrder(sale.id);
                    final paid = paymentProvider.getTotalPaidForSalesOrder(sale.id);
                    final remaining = total - paid;
                    final isMultiple = _isMultiplePayments(sale.paymentMethodId);
                    final statusColor = _getStatusColor(paid, total, isMultiple);
                    final statusText = _getStatusText(paid, total, isMultiple);
                    final isExpanded = _expandedSaleId == sale.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppTheme.goldBorderDecoration(),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _expandedSaleId = isExpanded ? null : sale.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Sale #${sale.id}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                if (isMultiple) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.mediumPurple.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'Multi-Payment',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppTheme.mediumPurple,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getCustomerName(sale.customerId),
                                              style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoColumn('Total', currencyFormat.format(total)),
                                      ),
                                      Expanded(
                                        child: _buildInfoColumn('Paid', currencyFormat.format(paid), color: AppTheme.success),
                                      ),
                                      Expanded(
                                        child: _buildInfoColumn('Remaining', currencyFormat.format(remaining), color: remaining > 0 ? AppTheme.error : AppTheme.mutedText),
                                      ),
                                      Icon(
                                        isExpanded ? Icons.expand_less : Icons.expand_more,
                                        color: AppTheme.primaryGold,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: AppTheme.mutedText),
                                      const SizedBox(width: 4),
                                      Text(
                                        sale.saleDate != null
                                            ? DateFormat('MMM dd, yyyy').format(sale.saleDate!)
                                            : 'N/A',
                                        style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.payment, size: 14, color: AppTheme.mutedText),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getPaymentMethodName(sale.paymentMethodId),
                                        style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded) ...[
                            Divider(color: AppTheme.lightGold),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // The tax split, when the sale has one (legacy
                                  // sales predate server-side tax and stay null).
                                  if (sale.subtotal != null || sale.taxAmount != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.percent, size: 14, color: AppTheme.mutedText),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Subtotal ${currencyFormat.format((sale.subtotal as num?)?.toDouble() ?? 0)} · IVA ${currencyFormat.format((sale.taxAmount as num?)?.toDouble() ?? 0)}',
                                            style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Payments (${payments.length})',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      // Only show Add Payment button if:
                                      // 1. There's remaining balance AND
                                      // 2. The payment method allows multiple payments (installments)
                                      if (remaining > 0 && isMultiple)
                                        TextButton.icon(
                                          onPressed: () => _showAddPaymentDialog(sale, remaining),
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Add Payment'),
                                          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGold),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (payments.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'No payments recorded',
                                          style: TextStyle(color: AppTheme.mutedText),
                                        ),
                                      ),
                                    )
                                  else
                                    ...payments.map((payment) => _buildPaymentCard(payment, pmProvider)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );

                return Column(
                  children: [
                    if (errorBanner != null) errorBanner,
                    Expanded(child: list),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.mutedText, fontSize: 11)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color)),
      ],
    );
  }

  Widget _buildPaymentCard(dynamic payment, PaymentMethodProvider pmProvider) {
    final paymentMethodName = _getPaymentMethodName(payment.paymentMethodId);
    final amount = (payment.amount as num?)?.toDouble() ?? 0;
    final date = payment.paymentDate != null
        ? DateFormat('MMM dd, yyyy').format(payment.paymentDate!)
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGold),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 35,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGold, AppTheme.secondaryGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                paymentMethodName.isNotEmpty
                    ? paymentMethodName.substring(0, paymentMethodName.length > 4 ? 4 : paymentMethodName.length).toUpperCase()
                    : 'PAY',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatCurrency(amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  paymentMethodName,
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: TextStyle(color: AppTheme.mutedText, fontSize: 11),
              ),
              if (payment.notes != null && payment.notes!.isNotEmpty)
                Text(
                  payment.notes!,
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }
}