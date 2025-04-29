import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'styles.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class WeatherDetailPage extends StatefulWidget {
  final String city;
  const WeatherDetailPage({super.key, required this.city});

  @override
  State<WeatherDetailPage> createState() => _WeatherDetailPageState();
}

class _WeatherDetailPageState extends State<WeatherDetailPage> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  bool isCelsius = true;
  final _feedbackController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  // For alerts
  bool rainAlert = false;
  bool snowAlert = false;
  int highTempAlert = 100;
  int lowTempAlert = 32;

  final String apiKey = '60dc03ec8d270d72c9cffb52e65414dc'; // Your OpenWeatherMap API Key

  @override
  void initState() {
    super.initState();
    _loadTemperatureUnitAndAlerts();
  }

  Future<void> _loadTemperatureUnitAndAlerts() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();

    if (data != null) {
      isCelsius = data['isCelsius'] ?? true;
      rainAlert = data['rainAlert'] ?? false;
      snowAlert = data['snowAlert'] ?? false;
      highTempAlert = data['highTempAlert'] ?? 100;
      lowTempAlert = data['lowTempAlert'] ?? 32;
    }

    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final units = isCelsius ? 'metric' : 'imperial';

    final url =
        'https://api.openweathermap.org/data/2.5/forecast?q=${widget.city}&units=$units&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });

        _checkAlerts(); // ✅ Check alerts after loading weather
      } else {
        _showError('Failed to load weather data.');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAlertPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _checkAlerts() {
    if (weatherData == null) return;

    final List<dynamic> list = weatherData?['list'] ?? [];

    List<String> triggeredAlerts = [];

    bool rainAdded = false;
    bool snowAdded = false;
    bool heatAdded = false;
    bool coldAdded = false;

    for (var forecast in list) {
      final description = forecast['weather'][0]['description'] as String;
      final temp = forecast['main']['temp'] as num;

      if (rainAlert && description.toLowerCase().contains('rain') && !rainAdded) {
        triggeredAlerts.add('🌧️ Rain expected. Don\'t forget your umbrella!');
        rainAdded = true;
      }
      if (snowAlert && description.toLowerCase().contains('snow') && !snowAdded) {
        triggeredAlerts.add('❄️ Snow expected. Stay warm!');
        snowAdded = true;
      }
      if (temp >= highTempAlert && !heatAdded) {
        triggeredAlerts.add('🔥 High temperature alert: Above $highTempAlert°!');
        heatAdded = true;
      }
      if (temp <= lowTempAlert && !coldAdded) {
        triggeredAlerts.add('🧊 Low temperature alert: Below $lowTempAlert°!');
        coldAdded = true;
      }
    }

    if (triggeredAlerts.isNotEmpty) {
      _showCombinedAlert(triggeredAlerts);
    }
  }


  void _showCombinedAlert(List<String> alerts) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Weather Alerts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: alerts.map((alert) => Text(alert)).toList(),
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }


  Widget _buildHourlyForecast() {
    final List<dynamic> list = weatherData?['list'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hourly Forecast',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            itemBuilder: (context, index) {
              if (index >= list.length) return const SizedBox();
              final hourData = list[index];
              final time = (hourData['dt_txt'] as String).split(' ')[1].substring(0, 5);
              final temp = (hourData['main']['temp'] as num).toStringAsFixed(0);
              final icon = (hourData['weather'][0]['icon'] as String);

              return Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(time),
                    Image.network(
                      'https://openweathermap.org/img/wn/$icon@2x.png',
                      width: 50,
                      height: 50,
                    ),
                    Text('$temp°'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecast() {
    final List<dynamic> list = weatherData?['list'] ?? [];

    final days = list.where((entry) => (entry['dt_txt'] as String).contains('12:00:00')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          '7-Day Forecast',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...days.map((day) {
          final date = (day['dt_txt'] as String).split(' ')[0];
          final temp = (day['main']['temp'] as num).toStringAsFixed(0);
          final desc = (day['weather'][0]['description'] as String);
          final icon = (day['weather'][0]['icon'] as String);

          return Card(
            color: Theme.of(context).cardColor.withOpacity(0.8),
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              leading: Image.network(
                'https://openweathermap.org/img/wn/$icon@2x.png',
                width: 50,
                height: 50,
              ),
              title: Text(date),
              subtitle: Text(desc),
              trailing: Text('$temp°'),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _submitFeedback() {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback submitted!')),
    );

    _feedbackController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundImage = themeProvider.backgroundImage;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: backgroundImage != null
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(backgroundImage),
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.city} Weather',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildHourlyForecast(),
                      _buildDailyForecast(),
                      const SizedBox(height: 30),
                      const Text(
                        'Share What You See:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _feedbackController,
                        decoration: const InputDecoration(
                          hintText: 'Describe the weather...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Submit Feedback'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
