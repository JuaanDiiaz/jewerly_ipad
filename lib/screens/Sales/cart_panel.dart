import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/sales_provider.dart';
import 'package:p_a_jewerly/providers/customer_provider.dart';
import 'package:p_a_jewerly/providers/payment_method_provider.dart';
import 'package:p_a_jewerly/providers/price_list_provider.dart';
import 'package:p_a_jewerly/providers/tax_rate_provider.dart';
import 'package:p_a_jewerly/providers/product_category_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/utils/format.dart';
import 'package:p_a_jewerly/utils/sales_tax.dart';
import 'package:p_a_jewerly/widgets/picked_image.dart';

/// The current-sale rail of the POS screen: customer + price-list + warehouse
/// selectors up top (kept visible while picking, the reason they moved here),
/// the live item list in the middle (tap-to-add fills it), and the tax/total +
/// payment + checkout block at the bottom. Serves both layouts — the tablet
/// side rail and the compact bottom sheet host the same widget.
class CartPanel extends StatefulWidget {
  final VoidCallback onCheckout;
  /// Fired when the price-list segmented control changes; the screen reprices
  /// the cart lines for the newly selected list.
  final ValueChanged<int?> onPriceListChanged;

  const CartPanel({
    super.key,
    required this.onCheckout,
    required this.onPriceListChanged,
  });

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final _salespersonController = TextEditingController();
  bool _wasCartEmpty = true;

  @override
  void initState() {
    super.initState();
    _salespersonController.text =
        context.read<SalesProvider>().salespersonName ?? '';
  }

  @override
  void dispose() {
    _salespersonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();

    // Checkout clears cart + customer + payment + salesperson state for the
    // next sale; the provider drop is authoritative, so mirror it in the text
    // field here instead of owning the reset from the screen.
    if (salesProvider.cart.isEmpty && !_wasCartEmpty) {
      _salespersonController.clear();
    }
    _wasCartEmpty = salesProvider.cart.isEmpty;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                'Current Sale',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${salesProvider.cart.length}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // Customer / price list / warehouse — visible while picking
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomerSelector(salesProvider),
              const SizedBox(height: 8),
              _buildPriceListSelector(salesProvider),
              const SizedBox(height: 8),
              _buildWarehouseSelector(salesProvider),
            ],
          ),
        ),
        // Items
        Expanded(
          child: salesProvider.cart.isEmpty
              ? _buildEmptyCart()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: salesProvider.cart.length,
                  itemBuilder: (context, index) {
                    final item = salesProvider.cart[index];
                    return _CartItemTile(
                      item: item,
                      onRemove: () =>
                          context.read<SalesProvider>().removeFromCart(item.productId),
                      onQuantityChanged: (qty) => context
                          .read<SalesProvider>()
                          .updateCartItemQuantity(item.productId, qty),
                      onPriceChanged: (price) => context
                          .read<SalesProvider>()
                          .updateCartItemPrice(item.productId, price),
                    );
                  },
                ),
        ),
        // Summary + checkout
        if (salesProvider.cart.isNotEmpty)
          _buildCheckoutBlock(salesProvider, cartTaxBreakdown(context, salesProvider)),
      ],
    );
  }

  Widget _buildCustomerSelector(SalesProvider salesProvider) {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, _) {
        return DropdownButtonFormField<int?>(
          decoration: InputDecoration(
            labelText: 'Customer',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
            filled: true,
            fillColor: AppTheme.background,
          ),
          value: salesProvider.selectedCustomerId,
          items: [
            DropdownMenuItem(
                value: null, child: Text('Tap to choose', style: TextStyle(color: AppTheme.mutedText))),
            ...customerProvider.customers.map((customer) {
              return DropdownMenuItem(
                value: customer.id,
                child: Text(customer.name, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: (value) {
            salesProvider.setCustomer(value);
            // If "multiple payments" was already chosen, picking the walk-in
            // can't keep it — it has no account to carry the balance.
            if (value != null && isOneTimeCustomer(customerProvider, value)) {
              final methods =
                  context.read<PaymentMethodProvider>().paymentMethods;
              final selected = methods
                  .where((m) => m.id == salesProvider.paymentMethodId)
                  .toList();
              if (selected.isNotEmpty &&
                  isMultiplePaymentsMethod(selected.first.description)) {
                salesProvider.setPaymentMethodId(null);
              }
            }
          },
        );
      },
    );
  }

  /// Retail / Wholesale / ... — the register always prices against one
  /// chosen list; the grid tiles and tap-to-add use its prices, and a switch
  /// here reprices the cart lines (see the screen's reprice handler).
  Widget _buildPriceListSelector(SalesProvider salesProvider) {
    return Consumer<PriceListProvider>(
      builder: (context, priceListProvider, _) {
        final lists = priceListProvider.priceLists;
        if (lists.isEmpty) {
          return SizedBox(
            width: double.infinity,
            child: Text(
              'No price lists configured',
              style: TextStyle(color: AppTheme.mutedText, fontStyle: FontStyle.italic),
            ),
          );
        }
        final selected = salesProvider.selectedPriceListId;
        return SegmentedButton<int>(
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            side: WidgetStatePropertyAll(BorderSide(color: AppTheme.primaryGold)),
          ),
          segments: lists
              .map((list) => ButtonSegment(
                    value: list.id,
                    label: Text(
                      list.description,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          selected: selected != null ? {selected} : {},
          onSelectionChanged: (selection) => widget.onPriceListChanged(selection.first),
        );
      },
    );
  }

  Widget _buildWarehouseSelector(SalesProvider salesProvider) {
    return Consumer<WarehouseProvider>(
      builder: (context, warehouseProvider, _) {
        return DropdownButtonFormField<int?>(
          decoration: InputDecoration(
            labelText: 'Warehouse',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.warehouse),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: AppTheme.background,
          ),
          value: salesProvider.selectedWarehouseId,
          items: [
            DropdownMenuItem(
                value: null, child: Text('Select warehouse', style: TextStyle(color: AppTheme.mutedText))),
            ...warehouseProvider.warehouses.map((wh) {
              return DropdownMenuItem(
                value: wh.id,
                child: Text(wh.name ?? 'Warehouse ${wh.id}',
                    overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: (value) => salesProvider.setWarehouse(value),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 64, color: AppTheme.mutedText),
          const SizedBox(height: 16),
          Text(
            'Cart is empty',
            style: TextStyle(color: AppTheme.mutedText, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a product to add it',
            style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBlock(SalesProvider salesProvider, CartTaxBreakdown tax) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: AppTheme.hairline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...buildTaxRows(tax, totalLabelWithTax: true),
          const SizedBox(height: 8),
          Consumer2<CustomerProvider, PaymentMethodProvider>(
            builder: (context, customerProvider, pmProvider, _) {
              // The walk-in "One time customer" has no account to accrue a
              // balance against — the multiple-payments method stays hidden
              // from its dropdown.
              final hideMultiple = isOneTimeCustomer(
                  customerProvider, salesProvider.selectedCustomerId);
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      decoration: InputDecoration(
                        labelText: 'Payment',
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      value: salesProvider.paymentMethodId,
                      items: [
                        const DropdownMenuItem(
                            value: null,
                            child:
                                Text('Payment method', style: TextStyle(fontSize: 13))),
                        ...pmProvider.paymentMethods
                            .where((method) =>
                                !(hideMultiple &&
                                    isMultiplePaymentsMethod(method.description)))
                            .map((method) {
                          return DropdownMenuItem(
                            value: method.id,
                            child: Text(method.description ?? 'Method ${method.id}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          );
                        }),
                      ],
                      onChanged: (value) => salesProvider.setPaymentMethodId(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Salesperson
                  Expanded(
                    child: TextFormField(
                      controller: _salespersonController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Salesperson',
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.badge, size: 18),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (value) => salesProvider.setSalesperson(value),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_checkout, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Checkout ${formatCurrency(tax.total)}',
                    style:
                        const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatefulWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<double> onPriceChanged;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onPriceChanged,
  });

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  late final TextEditingController _priceController;
  late final FocusNode _priceFocus;
  /// The item price the text currently shows — the reference point the
  /// dirty-check below compares against.
  late double _priceInField;

  @override
  void initState() {
    super.initState();
    _priceInField = widget.item.unitPrice;
    _priceController =
        TextEditingController(text: widget.item.unitPrice.toStringAsFixed(2));
    _priceFocus = FocusNode();
    // Committing on unfocus (not on tap-outside-losing-text) lets the user
    // back out with the back arrow: the field reverts to the item's price.
    _priceFocus.addListener(() {
      if (!_priceFocus.hasFocus) {
        final entered = double.tryParse(_normalizedPriceText()) ?? _priceInField;
        if (entered != _priceInField) {
          widget.onPriceChanged(entered < 0 ? 0 : entered);
          // Reprice is applied by the provider; didUpdateWidget syncs the text.
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External reprice (price-list switch or another sheet add): sync the
    // field unless the user is mid-edit on it. Writing the controller
    // notifies the enclosing Form, which marks itself dirty — that must not
    // happen synchronously mid-build, so defer a frame.
    if (widget.item.unitPrice != _priceInField && !_priceFocus.hasFocus) {
      final newPrice = widget.item.unitPrice;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _priceInField = newPrice;
        _priceController.text = newPrice.toStringAsFixed(2);
      });
    }
  }

  String _normalizedPriceText() => _priceController.text.trim().replaceAll(',', '.');

  @override
  void dispose() {
    _priceController.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atStockLimit =
        widget.item.maxQuantity > 0 && widget.item.quantity >= widget.item.maxQuantity;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGold.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
                      ? PickedImage(url: widget.item.imageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.diamond_outlined,
                          color: AppTheme.primaryGold, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.item.maxQuantity > 0)
                        Text(
                          // Stock ceiling feedback: flags when the cart is at
                          // (or over) it — same contract as the old tile.
                          '${widget.item.maxQuantity} available',
                          style: TextStyle(
                            color: atStockLimit ? AppTheme.error : AppTheme.mutedText,
                            fontSize: 11,
                            fontWeight: atStockLimit ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.error),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // Quantity stepper: 40x40 hit boxes, count tappable to type
                _buildStepper(),
                const Spacer(),
                // Price field
                SizedBox(
                  width: 108,
                  height: 40,
                  child: TextFormField(
                    controller: _priceController,
                    focusNode: _priceFocus,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      isDense: true,
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Text(
                    formatCurrency(widget.item.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (widget.item.quantity > 1) {
                widget.onQuantityChanged(widget.item.quantity - 1);
              } else {
                widget.onRemove();
              }
            },
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          InkWell(
            onTap: _promptQuantity,
            child: Container(
              constraints: const BoxConstraints(minWidth: 32),
              alignment: Alignment.center,
              child: Text(
                '${widget.item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () {
              // Stock ceiling: no silent clamp without explanation.
              if (widget.item.maxQuantity > 0 &&
                  widget.item.quantity >= widget.item.maxQuantity) {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Only ${widget.item.maxQuantity} available'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              HapticFeedback.lightImpact();
              widget.onQuantityChanged(widget.item.quantity + 1);
            },
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  /// Tapping the count opens a small input so a big number doesn't need
  /// repeated + taps.
  Future<void> _promptQuantity() async {
    final controller = TextEditingController(text: '${widget.item.quantity}');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Quantity — ${widget.item.productName}',
              style: const TextStyle(fontSize: 18)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: widget.item.maxQuantity > 0
                  ? 'Quantity (max ${widget.item.maxQuantity})'
                  : 'Quantity',
            ),
            onSubmitted: (value) => Navigator.pop(
                dialogContext, int.tryParse(value) ?? widget.item.quantity),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                  dialogContext, int.tryParse(controller.text) ?? widget.item.quantity),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result == null || result == widget.item.quantity) return;
    if (!mounted) return;
    if (widget.item.maxQuantity > 0) {
      final applied = result > widget.item.maxQuantity
          ? widget.item.maxQuantity
          : result;
      if (applied != result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only ${widget.item.maxQuantity} available'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      widget.onQuantityChanged(applied);
    } else {
      widget.onQuantityChanged(result);
    }
  }
}

/// IVA math from the live provider data: rates + product-category links +
/// cart. Read-only on purpose: this runs both in widget builds and inside
/// modal-sheet builders (out-of-build for the State that shows the checkout
/// sheet, where `context.watch` asserts) — the summary is rebuilt by every
/// cart/checkout state change anyway, and a rate edit landing mid-sheet is
/// not worth the subscription.
/// The walk-in "One time customer" is cash-at-the-counter — it has no account
/// to accrue a balance against, so the multiple-payments method must not be
/// selectable for it. Matched by name: the backend has no walk-in flag.
bool isOneTimeCustomer(CustomerProvider customers, int? customerId) {
  if (customerId == null) return false;
  for (final customer in customers.customers) {
    if (customer.id != customerId) continue;
    final name = customer.name.toLowerCase();
    return name.contains('one time') ||
        name.contains('mostrador') ||
        name.contains('walk-in');
  }
  return false;
}

/// Same three-way match as payment_method_provider's
/// ensureMultiplePaymentsMethod and sales_list_screen's _isMultiplePayments —
/// keep them in step.
bool isMultiplePaymentsMethod(String? description) {
  final desc = (description ?? '').toLowerCase();
  return desc.contains('multiple') || desc.contains('varias') || desc.contains('parcial');
}

CartTaxBreakdown cartTaxBreakdown(BuildContext context, SalesProvider salesProvider) {
  return computeCartTax(
    salesProvider.cart,
    context.read<TaxRateProvider>().taxRates,
    context.read<ProductCategoryProvider>().productCategories,
  );
}

/// The Subtotal / tax lines for the summary surfaces.
/// [totalLabelWithTax] true renders the bold Total row too (checkout
/// confirmation sheet); false leaves that to the caller.
List<Widget> buildTaxRows(CartTaxBreakdown tax, {required bool totalLabelWithTax}) {
  final rows = <Widget>[
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Subtotal', style: TextStyle(color: AppTheme.mutedText)),
        Text(formatCurrency(tax.subtotal)),
      ],
    ),
  ];
  for (final entry in tax.taxesByType.entries) {
    rows.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(entry.key, style: TextStyle(color: AppTheme.mutedText)),
        Text(formatCurrency(entry.value)),
      ],
    ));
  }
  if (totalLabelWithTax) {
    rows.add(const SizedBox(height: 6));
    rows.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(formatCurrency(tax.total),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.success)),
      ],
    ));
  }
  return rows;
}