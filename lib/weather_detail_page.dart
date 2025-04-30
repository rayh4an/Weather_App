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
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

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
  Uint8List? _selectedImage;

  final _feedbackController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();
  String getWeatherImage(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('rain')) return 'assets/rainy_bg.jpg';
    if (condition.contains('snow')) return 'assets/snowy_bg.jpg';
    if (condition.contains('cloud')) return 'assets/cloudy_bg.jpg';
    if (condition.contains('wind')) return 'assets/windy_bg.jpg';
    if (condition.contains('sun') || condition.contains('clear')) {
      return 'assets/sunny_bg.jpg';
    }
    return 'assets/default_bg.jpg';
  }

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
  } //

  //
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
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

  Color getBackgroundColor() {
    if (weatherData == null) return Colors.grey.shade300;

    final timestamp = (weatherData!['list'][0]['dt'] as int) * 1000;
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal();
    final hour = dateTime.hour;

    final condition = weatherData!['list'][0]['weather'][0]['main'] as String;

    if (condition.toLowerCase().contains("rain")) {
      return const Color.fromARGB(255, 138, 136, 136);
    } else if (condition.toLowerCase().contains("snow")) {
      return Colors.blueGrey.shade300;
    } else if (condition.toLowerCase().contains("cloud")) {
      return Colors.blueGrey.shade100;
    } else if (hour >= 6 && hour < 12) {
      return const Color.fromARGB(255, 234, 235, 133); // Morning
    } else if (hour >= 12 && hour < 18) {
      return const Color.fromARGB(255, 118, 183, 235); // Afternoon
    } else if (hour >= 18 && hour < 20) {
      return const Color.fromARGB(255, 33, 144, 248); // Evening
    } else {
      return const Color.fromARGB(255, 37, 120, 161); // Night
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
                decoration: BoxDecoration(
                  image:
                      backgroundImage != null
                          ? DecorationImage(
                            image: AssetImage(backgroundImage),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              getBackgroundColor().withOpacity(0.6),
                              BlendMode.srcOver,
                            ),
                          )
                          : null,
                  color: getBackgroundColor(),
                ),

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
                            filled: true,
                            fillColor: Colors.white, // sets background to white
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _submitFeedback,
                          icon: const Icon(
                            Icons.send,
                            color: Color.fromRGBO(0, 0, 0, 1),
                          ),
                          label: const Text(
                            'Submit Feedback',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                          ),
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
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                          ),
                          child: const Text(
                            'Add Image to Postcard',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
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
                              height: 250,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: AssetImage(
                                    getWeatherImage(
                                      weatherData?['list'][0]['weather'][0]['description'] ??
                                          '',
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // User-selected image near the top-right with padding
                                  if (_selectedImage != null)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          _selectedImage!,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  // Main content centered
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Current Weather',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '${weatherData?['list'][0]['main']['temp'].toStringAsFixed(0)}°',
                                          style: const TextStyle(
                                            fontSize: 50,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          weatherData?['list'][0]['weather'][0]['description'] ??
                                              '',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Color.fromARGB(
                                              255,
                                              44,
                                              44,
                                              44,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Shared by: ${user?.email ?? "User"}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color.fromARGB(179, 0, 0, 0),
                                          ),
                                        ),
                                      ],
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
                          icon: const Icon(
                            Icons.share,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          label: const Text(
                            'Share Weather',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
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
