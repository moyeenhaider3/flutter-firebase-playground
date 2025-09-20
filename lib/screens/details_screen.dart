import 'package:flutter/material.dart';

class DetailsScreen extends StatelessWidget {
  final String id;
  const DetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Center(
        child: Text('Opened via notification payload. Item id: $id'),
      ),
    );
  }
}
