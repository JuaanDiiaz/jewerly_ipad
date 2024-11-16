import 'package:flutter/material.dart';

class PhysicalCountMainScreen extends StatelessWidget {
  const PhysicalCountMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> items = [
      {'name': 'Gold Necklace', 'image': 'assets/gold_necklace.jpeg'},
      {'name': 'Diamond Ring', 'image': 'assets/diamond_ring.jpg'},
      {'name': 'Gold Earrings', 'image': 'assets/gold_earrings.jpeg'},
      {'name': 'Gold Watch', 'image': 'assets/gold_watch.jpg'},
      {'name': 'Diamond Necklace', 'image': 'assets/diamond_necklace.webp'},
      {'name': 'Gold Bracelet', 'image': 'assets/gold_bracelet.webp'},
      {'name': 'Diamond Bracelet', 'image': 'assets/diamond_bracelet.jpg'},
      {'name': 'Diamond Earrings', 'image': 'assets/diamond_earrings.jpeg'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Physical Count'),
        backgroundColor: Colors.amber[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3 / 4,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 5,
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
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Count',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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