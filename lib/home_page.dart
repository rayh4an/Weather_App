import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'styles.dart';
import 'settings_page.dart';
import 'weather_detail_page.dart';
import 'theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> locations = [];
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserLocations();
  }

  Future<void> _loadUserLocations() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      setState(() {
        locations = List<String>.from(data?['locations'] ?? []);
      });
    }
  }

  Future<void> _addLocation(String city) async {
    if (city.isEmpty) return;

    setState(() {
      locations.add(city);
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({
      'locations': locations,
    }, SetOptions(merge: true));
  }

  Future<void> _deleteLocation(String city) async {
    locations.remove(city);
    setState(() {});
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({
      'locations': locations,
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location deleted')),
    );
  }


  void _showAddLocationDialog() {
    final cityController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Location'),
        content: TextField(
          controller: cityController,
          decoration: const InputDecoration(hintText: 'Enter city name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addLocation(cityController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
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
        backgroundColor: Theme.of(context).primaryColor,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLocationDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greetingMessage()}, ${user?.email ?? ''}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Today is: ${DateTime.now().toLocal().toString().split(' ')[0]} - ${_getWeekdayName(DateTime.now().weekday)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: locations.isEmpty
                    ? const Center(child: Text('No locations added yet.'))
                    : ListView.builder(
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final city = locations[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Theme.of(context).cardColor.withOpacity(0.8),
                            child: ListTile(
                              title: Text(
                                city,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteLocation(city),
                                  ),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WeatherDetailPage(city: city),
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
