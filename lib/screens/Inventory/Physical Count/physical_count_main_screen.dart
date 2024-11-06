import 'package:flutter/material.dart';

class PhysicalCountMainScreen extends StatelessWidget {
  const PhysicalCountMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Physical count'),
      ),
      body: Center(
        child: Text('Physical count'),
      ),
    );
  }
}