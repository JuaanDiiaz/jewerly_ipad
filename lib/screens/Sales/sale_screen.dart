import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  _SaleScreenState createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final List<Map<String, dynamic>> items = [
    {'name': 'Gold Necklace', 'image': 'assets/gold_necklace.jpeg', 'quantity': 10},
    {'name': 'Diamond Ring', 'image': 'assets/diamond_ring.jpg', 'quantity': 5},
    {'name': 'Gold Earrings', 'image': 'assets/gold_earrings.jpeg', 'quantity': 8},
    {'name': 'Gold Watch', 'image': 'assets/gold_watch.jpg', 'quantity': 3},
    {'name': 'Diamond Necklace', 'image': 'assets/diamond_necklace.webp', 'quantity': 7},
    {'name': 'Gold Bracelet', 'image': 'assets/gold_bracelet.webp', 'quantity': 6},
    {'name': 'Diamond Bracelet', 'image': 'assets/diamond_bracelet.jpg', 'quantity': 4},
    {'name': 'Diamond Earrings', 'image': 'assets/diamond_earrings.jpeg', 'quantity': 9},
  ];

  final List<Map<String, dynamic>> _cart = [];
  String? _selectedCustomer;
  String? _selectedPaymentMethod;
  String? _salespersonName;

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      _cart.add(item);
    });
    Fluttertoast.showToast(
      msg: "${item['name']} added to cart",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _removeFromCart(Map<String, dynamic> item) {
    setState(() {
      _cart.remove(item);
    });
  }

  void _showSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
                    Text(
                      'Sale Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('Customer: $_selectedCustomer'),
                    Text('Salesperson: $_salespersonName'),
                    Text('Payment Method: $_selectedPaymentMethod'),
                    SizedBox(height: 10),
                    Text(
                      'Cart Items:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ..._cart.map((item) => ListTile(
                          title: Text(item['name']),
                          leading: Image.asset(item['image'], width: 50, height: 50),
                          subtitle: Text('Quantity: ${item['quantity']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_shopping_cart),
                            onPressed: () => _removeFromCart(item),
                          ),
                        )),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle checkout action
                        },
                        child: Text('Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Customer'),
              items: ['Customer 1', 'Customer 2', 'Customer 3']
                  .map((customer) => DropdownMenuItem(
                        value: customer,
                        child: Text(customer),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCustomer = value;
                });
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: 'Salesperson Name'),
              onChanged: (value) {
                setState(() {
                  _salespersonName = value;
                });
              },
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Payment Method'),
              items: ['Cash', 'Credit Card', 'Debit Card']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _AnimatedItemCard(
                    item: item,
                    onAddToCart: () => _addToCart(item),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _showSummary,
              child: Text('View Summary'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onAddToCart;

  const _AnimatedItemCard({
    required this.item,
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
    widget.onAddToCart();
    _controller.forward().then((_) {
      _controller.reverse();
    });
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(
                widget.item['image'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text('Available: ${widget.item['quantity']}'),
                SizedBox(height: 5),
                Center(
                  child: ScaleTransition(
                    scale: _animation,
                    child: ElevatedButton(
                      onPressed: _handleAddToCart,
                      child: Text('Add to Cart'),
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
