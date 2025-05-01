// home_page.dart (Fixed Version)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'styles.dart';
import 'settings_page.dart';
import 'weather_detail_page.dart';
import 'theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> locations = [];
  final user = FirebaseAuth.instance.currentUser;
  void _showAddLocationDialog() {
    final cityController = TextEditingController();
    List<dynamic> suggestions = [];

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Add a City'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          hintText: 'Type city name...',
                        ),
                        onChanged: (value) async {
                          if (value.isEmpty) return;
                          final url = Uri.parse(
                            'http://api.openweathermap.org/geo/1.0/direct?q=$value&limit=5&appid=60dc03ec8d270d72c9cffb52e65414dc',
                          );
                          final response = await http.get(url);
                          if (response.statusCode == 200) {
                            setState(() {
                              suggestions = jsonDecode(response.body);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      ...suggestions.map((s) {
                        final city = s['name'];
                        final country = s['country'];
                        final lat = s['lat'];
                        final lon = s['lon'];
                        return ListTile(
                          title: Text('$city, $country'),
                          onTap: () {
                            _addLocation(city, lat, lon);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserLocations();
  }

  Future<void> _getWeatherForCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission permanently denied.'),
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final lat = position.latitude;
    final lon = position.longitude;

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=imperial&appid=60dc03ec8d270d72c9cffb52e65414dc',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final city = data['name'];
        final temp = data['main']['temp'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current weather in $city: $temp°F')),
        );

        if (!locations.any((e) => e['name'] == city)) {
          await _addLocation(city, lat, lon);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addLocation(String city, double lat, double lon) async {
    final newCity = {'name': city, 'lat': lat, 'lon': lon};
    setState(() {
      locations.add(newCity);
    });

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'locations': locations,
    }, SetOptions(merge: true));
  }

  Future<void> _loadUserLocations() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    if (snapshot.exists) {
      final data = snapshot.data();
      final List<dynamic> raw = data?['locations'] ?? [];
      setState(() {
        locations = raw.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _deleteLocation(Map<String, dynamic> cityInfo) async {
    locations.removeWhere((loc) => loc['name'] == cityInfo['name']);
    setState(() {});
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'locations': locations,
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Location deleted')));
  }

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getWeekdayName(int weekday) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundImage = themeProvider.backgroundImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weatherly Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),

      // FABs for location + add city
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'locationBtn',
            onPressed: _getWeatherForCurrentLocation,
            tooltip: 'Use My Location',
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'addBtn',
            onPressed: _showAddLocationDialog,
            tooltip: 'Add City',
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add),
          ),
        ],
      ),

      body: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greetingMessage()}, ${user?.email ?? ''}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Today is: ${DateTime.now().toLocal().toString().split(' ')[0]} - ${_getWeekdayName(DateTime.now().weekday)}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Expanded(
                child:
                    locations.isEmpty
                        ? const Center(child: Text('No locations added yet.'))
                        : ListView.builder(
                          itemCount: locations.length,
                          itemBuilder: (context, index) {
                            final cityInfo = locations[index];
                            final cityName = cityInfo['name'];
                            final lat = cityInfo['lat'];
                            final lon = cityInfo['lon'];

                            return Card(
                              child: ListTile(
                                title: Text(cityName),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteLocation(cityInfo),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => WeatherDetailPage(
                                            city: cityName,
                                            lat: lat,
                                            lon: lon,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
