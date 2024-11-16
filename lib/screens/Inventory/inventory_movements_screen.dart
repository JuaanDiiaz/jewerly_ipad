import 'package:flutter/material.dart';

class InventoryMovementsScreen extends StatelessWidget {
  const InventoryMovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> movements = [
      {'date': '2023-10-01', 'item': 'Gold Necklace', 'quantity': '2', 'type': 'Added'},
      {'date': '2023-10-02', 'item': 'Diamond Ring', 'quantity': '1', 'type': 'Removed'},
      {'date': '2023-10-03', 'item': 'Silver Bracelet', 'quantity': '5', 'type': 'Added'},
      {'date': '2023-10-04', 'item': 'Platinum Earrings', 'quantity': '3', 'type': 'Removed'},
      {'date': '2023-10-05', 'item': 'Gold Watch', 'quantity': '1', 'type': 'Added'},
      {'date': '2023-10-06', 'item': 'Diamond Necklace', 'quantity': '2', 'type': 'Removed'},
      {'date': '2023-10-07', 'item': 'Silver Ring', 'quantity': '4', 'type': 'Added'},
      {'date': '2023-10-08', 'item': 'Platinum Bracelet', 'quantity': '1', 'type': 'Removed'},
      {'date': '2023-10-09', 'item': 'Gold Earrings', 'quantity': '3', 'type': 'Added'},
      {'date': '2023-10-10', 'item': 'Diamond Bracelet', 'quantity': '2', 'type': 'Removed'},
      {'date': '2023-10-11', 'item': 'Silver Watch', 'quantity': '1', 'type': 'Added'},
      {'date': '2023-10-12', 'item': 'Platinum Ring', 'quantity': '4', 'type': 'Removed'},
      {'date': '2023-10-13', 'item': 'Gold Bracelet', 'quantity': '2', 'type': 'Added'},
      {'date': '2023-10-14', 'item': 'Diamond Earrings', 'quantity': '1', 'type': 'Removed'},
      {'date': '2023-10-15', 'item': 'Silver Necklace', 'quantity': '3', 'type': 'Added'},
      {'date': '2023-10-16', 'item': 'Platinum Watch', 'quantity': '2', 'type': 'Removed'},
      {'date': '2023-10-17', 'item': 'Gold Ring', 'quantity': '1', 'type': 'Added'},
      {'date': '2023-10-18', 'item': 'Diamond Watch', 'quantity': '4', 'type': 'Removed'},
      {'date': '2023-10-19', 'item': 'Silver Earrings', 'quantity': '2', 'type': 'Added'},
      {'date': '2023-10-20', 'item': 'Platinum Necklace', 'quantity': '1', 'type': 'Removed'},
      {'date': '2023-10-21', 'item': 'Gold Watch', 'quantity': '3', 'type': 'Added'},
      {'date': '2023-10-22', 'item': 'Diamond Ring', 'quantity': '2', 'type': 'Removed'},
      {'date': '2023-10-23', 'item': 'Silver Bracelet', 'quantity': '1', 'type': 'Added'},
      {'date': '2023-10-24', 'item': 'Platinum Earrings', 'quantity': '4', 'type': 'Removed'},
      {'date': '2023-10-25', 'item': 'Gold Necklace', 'quantity': '2', 'type': 'Added'},
      {'date': '2023-10-26', 'item': 'Diamond Bracelet', 'quantity': '1', 'type': 'Removed'},
      {'date': '2023-10-27', 'item': 'Silver Ring', 'quantity': '3', 'type': 'Added'},
      {'date': '2023-10-28', 'item': 'Platinum Watch', 'quantity': '2', 'type': 'Removed'},
      {'date': '2023-10-29', 'item': 'Gold Earrings', 'quantity': '1', 'type': 'Added'},
      {'date': '2023-10-30', 'item': 'Diamond Necklace', 'quantity': '4', 'type': 'Removed'},
      {'date': '2023-10-31', 'item': 'Silver Watch', 'quantity': '2', 'type': 'Added'},
      {'date': '2023-11-01', 'item': 'Platinum Ring', 'quantity': '1', 'type': 'Removed'},
      {'date': '2023-11-02', 'item': 'Gold Bracelet', 'quantity': '4', 'type': 'Added'},
      {'date': '2023-11-03', 'item': 'Diamond Earrings', 'quantity': '2', 'type': 'Removed'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Movements'),
        backgroundColor: Colors.amber[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: movements.length,
          itemBuilder: (context, index) {
            final movement = movements[index];
            return Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  movement['type'] == 'Added' ? Icons.add_circle : Icons.remove_circle,
                  color: movement['type'] == 'Added' ? Colors.green : Colors.red,
                  size: 40,
                ),
                title: Text(
                  movement['item']!,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Date: ${movement['date']}\nQuantity: ${movement['quantity']}'),
                trailing: Text(
                  movement['type']!,
                  style: TextStyle(
                    color: movement['type'] == 'Added' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}