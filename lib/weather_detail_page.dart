import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'styles.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

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
  final ScreenshotController _screenshotController = ScreenshotController();

  final user = FirebaseAuth.instance.currentUser;

  bool showTemperatureOverlay = false;
  final MapController mapController = MapController();

  bool rainAlert = false;
  bool snowAlert = false;
  int highTempAlert = 100;
  int lowTempAlert = 32;

  final String apiKey = '60dc03ec8d270d72c9cffb52e65414dc';
  double lat = 40.7128;
  double lon = -74.0060;

  @override
  void initState() {
    super.initState();
    _loadTemperatureUnitAndAlerts();
  }

  Future<void> _loadTemperatureUnitAndAlerts() async {
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
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
        final data = json.decode(response.body);
        setState(() {
          weatherData = data;
          lat = data['city']['coord']['lat'];
          lon = data['city']['coord']['lon'];
          isLoading = false;
        });

        _checkAlerts();
      } else {
        _showError('Failed to load weather data.');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAlertPopup(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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

      if (rainAlert &&
          description.toLowerCase().contains('rain') &&
          !rainAdded) {
        triggeredAlerts.add('🌧️ Rain expected. Don\'t forget your umbrella!');
        rainAdded = true;
      }
      if (snowAlert &&
          description.toLowerCase().contains('snow') &&
          !snowAdded) {
        triggeredAlerts.add('❄️ Snow expected. Stay warm!');
        snowAdded = true;
      }
      if (temp >= highTempAlert && !heatAdded) {
        triggeredAlerts.add(
          '🔥 High temperature alert: Above $highTempAlert°!',
        );
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
      builder:
          (_) => AlertDialog(
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
              final time = (hourData['dt_txt'] as String)
                  .split(' ')[1]
                  .substring(0, 5);
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
    final days =
        list
            .where((entry) => (entry['dt_txt'] as String).contains('12:00:00'))
            .toList();

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

  void _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty || user == null) return;

    await FirebaseFirestore.instance.collection('global_feedbacks').add({
      'uid': user!.uid,
      'email': user!.email,
      'city': widget.city,
      'text': feedback,
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback submitted!')));
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration:
                    backgroundImage != null
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
                          'Radar Map',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 300,
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: mapController,
                                options: MapOptions(
                                  center: LatLng(lat, lon),
                                  zoom: 5,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                    userAgentPackageName:
                                        'com.example.weather_app',
                                  ),
                                  if (showTemperatureOverlay)
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=$apiKey',
                                      tileSize: 256,
                                    ),
                                ],
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      // Temperature toggle
                                      Row(
                                        children: [
                                          const Text(
                                            "Temp",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Switch(
                                            value: showTemperatureOverlay,
                                            onChanged: (val) {
                                              setState(() {
                                                showTemperatureOverlay = val;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Zoom buttons
                                      FloatingActionButton(
                                        heroTag: 'zoomIn',
                                        mini: true,
                                        backgroundColor: Colors.white,
                                        onPressed: () {
                                          mapController.move(
                                            mapController.center,
                                            mapController.zoom + 1,
                                          );
                                        },
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      FloatingActionButton(
                                        heroTag: 'zoomOut',
                                        mini: true,
                                        backgroundColor: Colors.white,
                                        onPressed: () {
                                          mapController.move(
                                            mapController.center,
                                            mapController.zoom - 1,
                                          );
                                        },
                                        child: const Icon(
                                          Icons.remove,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          'Share What You See:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                        const SizedBox(height: 20),
                        const Text(
                          'What Others Are Seeing:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('global_feedbacks')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final docs = snapshot.data!.docs;
                            return Container(
                              height: 300, // Adjust height as needed
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView(
                                children:
                                    docs.map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      return Card(
                                        elevation: 2,
                                        child: ListTile(
                                          title: Text(data['text'] ?? ''),
                                          subtitle: Text(
                                            '${data['email'] ?? 'Anonymous'} — ${data['city'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Share the Weather:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Screenshot(
                            controller: _screenshotController,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.blueAccent,
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Current Weather Mood',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${weatherData?['list'][0]['main']['temp'].toStringAsFixed(0)}°',
                                    style: const TextStyle(
                                      fontSize: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    weatherData?['list'][0]['weather'][0]['description'] ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Shared by: ${user?.email ?? "User"}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final image = await _screenshotController.capture();
                            if (image == null) return;

                            final directory = await getTemporaryDirectory();
                            final imagePath =
                                await File(
                                  '${directory.path}/weather_postcard.png',
                                ).create();
                            await imagePath.writeAsBytes(image);

                            await Share.shareXFiles([
                              XFile(imagePath.path),
                            ], text: 'Check out the weather!');
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share Weather'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
