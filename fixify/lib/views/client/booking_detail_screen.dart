import 'package:flutter/material.dart';

class BookingDetailScreen extends StatelessWidget {
  final String requestId;
  const BookingDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Detail')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}