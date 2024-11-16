import 'package:flutter/material.dart';

class InventoryMainScreen extends StatefulWidget {
  @override
  _InventoryMainScreenState createState() => _InventoryMainScreenState();
}

class _InventoryMainScreenState extends State<InventoryMainScreen> {
  String? _selectedWarehouse;
  Map<String, String>? _selectedArticle;
  String? _goldKaratage;
  final List<String> _warehouses = ['Warehouse 1'];
  final List<Map<String, String>> _articles = [
    {'name': 'Gold Necklace', 'image': 'assets/gold_necklace.jpeg'},
    {'name': 'Diamond Ring', 'image': 'assets/diamond_ring.jpg'},
    {'name': 'Gold Earrings', 'image': 'assets/gold_earrings.jpeg'},
    {'name': 'Gold Watch', 'image': 'assets/gold_watch.jpg'},
    {'name': 'Diamond Necklace', 'image': 'assets/diamond_necklace.webp'},
    {'name': 'Gold Bracelet', 'image': 'assets/gold_bracelet.webp'},
    {'name': 'Diamond Bracelet', 'image': 'assets/diamond_bracelet.jpg'},
    {'name': 'Diamond Earrings', 'image': 'assets/diamond_earrings.jpeg'},
  ];
  final TextEditingController _karatageController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Management'),
        backgroundColor: Colors.amber[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Warehouse'),
              value: _selectedWarehouse,
              items: _warehouses.map((warehouse) {
                return DropdownMenuItem<String>(
                  value: warehouse,
                  child: Text(warehouse),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWarehouse = value;
                });
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: _articles.length,
                itemBuilder: (context, index) {
                  final item = _articles[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedArticle = item;
                        _quantityController.text = '';
                      });
                    },
                    child: Card(
                      elevation: 5,
                      color: _selectedArticle == item ? Colors.amber[100] : null,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.asset(
                                item['image']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              item['name']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            if (_selectedArticle == item)
                              TextField(
                                controller: _quantityController,
                                decoration: InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _karatageController,
              decoration: InputDecoration(labelText: 'Gold Karatage'),
              onChanged: (value) {
                setState(() {
                  _goldKaratage = value;
                });
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedWarehouse != null && _selectedArticle != null && _goldKaratage != null && _quantityController.text.isNotEmpty) {
                // Add the new article to the warehouse
                print('Warehouse: $_selectedWarehouse, Article: ${_selectedArticle!['name']}, Gold Karatage: $_goldKaratage, Quantity: ${_quantityController.text}');
                // Clear the fields
                setState(() {
                  _selectedArticle = null;
                  _goldKaratage = null;
                  _karatageController.clear();
                  _quantityController.clear();
                });
              } else {
                // Show an error message
                print('Please fill all fields');
              }
            },
            child: Text('Add Article'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new item count
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}
