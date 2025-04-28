import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'styles.dart';

class WeatherDetailPage extends StatefulWidget {
  final String city;
  const WeatherDetailPage({super.key, required this.city});

  @override
  State<WeatherDetailPage> createState() => _WeatherDetailPageState();
}

class _WeatherDetailPageState extends State<WeatherDetailPage> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  final _feedbackController = TextEditingController();

  final String apiKey = '60dc03ec8d270d72c9cffb52e65414dc'; //API Key

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?q=${widget.city}&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
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

  Widget _buildHourlyForecast() {
    final list = weatherData?['list'] ?? [];
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
            itemCount: 12, // Show next 12 hours
            itemBuilder: (context, index) {
              if (index >= list.length) return const SizedBox();
              final hourData = list[index];
              final time = hourData['dt_txt'].split(' ')[1].substring(0, 5);
              final temp = hourData['main']['temp'].toStringAsFixed(0);
              final icon = hourData['weather'][0]['icon'];

              return Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.8),
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

    // Pick one forecast per day (around noon)
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
            color: AppColors.primaryBlue.withOpacity(0.8),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Submit Feedback'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
