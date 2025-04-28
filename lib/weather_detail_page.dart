import 'package:flutter/material.dart';
//placeholder
class WeatherDetailPage extends StatelessWidget {
  final String city;
  const WeatherDetailPage({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(city),
      ),
      body: const Center(
        child: Text('Weather Details Coming Soon!'),
      ),
    );
  }
}
