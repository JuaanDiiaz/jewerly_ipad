import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/sales_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/customer_provider.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  _SaleScreenState createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final List<Map<String, dynamic>> _products = [
    {'id': 1, 'name': 'Gold Necklace', 'image': 'assets/gold_necklace.jpeg', 'quantity': 10, 'price': 299.99},
    {'id': 2, 'name': 'Diamond Ring', 'image': 'assets/diamond_ring.jpg', 'quantity': 5, 'price': 599.99},
    {'id': 3, 'name': 'Gold Earrings', 'image': 'assets/gold_earrings.jpeg', 'quantity': 8, 'price': 199.99},
    {'id': 4, 'name': 'Gold Watch', 'image': 'assets/gold_watch.jpg', 'quantity': 3, 'price': 449.99},
    {'id': 5, 'name': 'Diamond Necklace', 'image': 'assets/diamond_necklace.webp', 'quantity': 7, 'price': 899.99},
    {'id': 6, 'name': 'Gold Bracelet', 'image': 'assets/gold_bracelet.webp', 'quantity': 6, 'price': 249.99},
    {'id': 7, 'name': 'Diamond Bracelet', 'image': 'assets/diamond_bracelet.jpg', 'quantity': 4, 'price': 699.99},
    {'id': 8, 'name': 'Diamond Earrings', 'image': 'assets/diamond_earrings.jpeg', 'quantity': 9, 'price': 399.99},
  ];

  final _salespersonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _salespersonController.dispose();
    super.dispose();
  }

  void _addToCart(Map<String, dynamic> product) {
    context.read<SalesProvider>().addToCart(CartItem(
      productId: product['id'],
      productName: product['name'],
      quantity: 1,
      unitPrice: product['price'],
      imageUrl: product['image'],
    ));

    Fluttertoast.showToast(
      msg: "${product['name']} added to cart",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showSummary() {
    if (context.read<SalesProvider>().cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Add items before checkout.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<SalesProvider>(
          builder: (context, salesProvider, _) {
            return DraggableScrollableSheet(
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sale Summary',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow('Customer', _getCustomerName(salesProvider.selectedCustomerId)),
                        _buildSummaryRow('Salesperson', salesProvider.salespersonName ?? 'Not specified'),
                        _buildSummaryRow('Payment Method', salesProvider.paymentMethod ?? 'Not selected'),
                        const SizedBox(height: 16),
                        const Text(
                          'Cart Items:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...salesProvider.cart.map((item) => Card(
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Text('\$${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_shopping_cart, color: Colors.red),
                                  onPressed: () => salesProvider.removeFromCart(item.productId),
                                ),
                              ],
                            ),
                          ),
                        )),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${salesProvider.cartTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Consumer<SalesProvider>(
                          builder: (context, provider, _) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: provider.isLoading ? null : _processCheckout,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Checkout', style: TextStyle(fontSize: 16)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getCustomerName(int? customerId) {
    if (customerId == null) return 'Not selected';
    final customerProvider = context.read<CustomerProvider>();
    try {
      final customer = customerProvider.customers.firstWhere(
        (c) => c.id == customerId,
      );
      return customer.name;
    } catch (_) {
      return 'Customer #$customerId';
    }
  }

  Future<void> _processCheckout() async {
    final salesProvider = context.read<SalesProvider>();

    if (salesProvider.selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('Please select a customer'),
      );
      return;
    }

    if (salesProvider.paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('Please select a payment method'),
      );
      return;
    }

    final success = await salesProvider.checkout();

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        successSnackBar('Sale completed successfully!'),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(salesProvider.error ?? 'Failed to complete sale'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return _AnimatedItemCard(
                    product: product,
                    onAddToCart: () => _addToCart(product),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Consumer<SalesProvider>(
                builder: (context, salesProvider, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              value: salesProvider.selectedCustomerId,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Select customer')),
                                ...(context.watch<CustomerProvider>().customers.map((customer) {
                                  return DropdownMenuItem(
                                    value: customer.id,
                                    child: Text(customer.name),
                                  );
                                })),
                              ],
                              onChanged: (value) {
                                salesProvider.setCustomer(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Payment Method',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.payment),
                              ),
                              initialValue: salesProvider.paymentMethod,
                              items: const [
                                DropdownMenuItem(value: null, child: Text('Select method')),
                                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
                                DropdownMenuItem(value: 'Debit Card', child: Text('Debit Card')),
                                DropdownMenuItem(value: 'Transfer', child: Text('Bank Transfer')),
                              ],
                              onChanged: (value) {
                                salesProvider.setPaymentMethod(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _salespersonController,
                              decoration: const InputDecoration(
                                labelText: 'Salesperson',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                              onChanged: (value) {
                                salesProvider.setSalesperson(value);
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _showSummary,
                            icon: const Icon(Icons.shopping_cart),
                            label: Text('Cart (${salesProvider.cart.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedItemCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;

  const _AnimatedItemCard({
    required this.product,
    required this.onAddToCart,
  });

  @override
  __AnimatedItemCardState createState() => __AnimatedItemCardState();
}

class __AnimatedItemCardState extends State<_AnimatedItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAddToCart() {
    if (widget.product['quantity'] > 0) {
      widget.onAddToCart();
      _controller.forward().then((_) {
        _controller.reverse();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product out of stock'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.product['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                  if (widget.product['quantity'] == 0)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  '\$${widget.product['price'].toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  'Available: ${widget.product['quantity']}',
                  style: TextStyle(
                    color: widget.product['quantity'] > 0 ? Colors.grey : Colors.red,
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: ScaleTransition(
                    scale: _animation,
                    child: ElevatedButton(
                      onPressed: widget.product['quantity'] > 0 ? _handleAddToCart : null,
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
