import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'styles.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool isCelsius = true;
  bool rainAlert = false;
  bool snowAlert = false;
  int highTempAlert = 100;
  int lowTempAlert = 32;

  final TextEditingController _highTempController = TextEditingController();
  final TextEditingController _lowTempController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        isCelsius = data['isCelsius'] ?? true;
        rainAlert = data['rainAlert'] ?? false;
        snowAlert = data['snowAlert'] ?? false;
        highTempAlert = data['highTempAlert'] ?? 100;
        lowTempAlert = data['lowTempAlert'] ?? 32;
        _highTempController.text = highTempAlert.toString();
        _lowTempController.text = lowTempAlert.toString();
      });
    }
  }

  Future<void> _updateUserSetting(String field, dynamic value) async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      field: value,
    }, SetOptions(merge: true));
  }

  Future<void> _saveTemperatureAlerts() async {
    await _updateUserSetting('highTempAlert', int.tryParse(_highTempController.text) ?? 100);
    await _updateUserSetting('lowTempAlert', int.tryParse(_lowTempController.text) ?? 32);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Temperature alerts updated!')),
    );
  }

  void _toggleTemperatureUnit() async {
    setState(() {
      isCelsius = !isCelsius;
    });
    await _updateUserSetting('isCelsius', isCelsius);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Temperature unit set to ${isCelsius ? "Celsius" : "Fahrenheit"}')),
    );
  }

  void _toggleRainAlert(bool value) async {
    setState(() {
      rainAlert = value;
    });
    await _updateUserSetting('rainAlert', value);
  }

  void _toggleSnowAlert(bool value) async {
    setState(() {
      snowAlert = value;
    });
    await _updateUserSetting('snowAlert', value);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final wallpapers = {
      WallpaperOption.defaultTheme: 'Default',
      WallpaperOption.snow: 'Snow',
      WallpaperOption.space: 'Space',
      WallpaperOption.lightning: 'Lightning',
      WallpaperOption.water: 'Water',
      WallpaperOption.wood: 'Wood',
    };

    final backgroundImage = themeProvider.backgroundImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
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
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              _buildWallpaperCard(themeProvider, wallpapers),
              const SizedBox(height: 20),
              _buildTemperatureUnitCard(),
              const SizedBox(height: 20),
              _buildAlertsCard(),
              const SizedBox(height: 20),
              _buildLogoutCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWallpaperCard(ThemeProvider themeProvider, Map<WallpaperOption, String> wallpapers) {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.wallpaper),
        title: const Text('Select Wallpaper'),
        subtitle: DropdownButton<WallpaperOption>(
          value: themeProvider.selectedWallpaper,
          onChanged: (WallpaperOption? newValue) async {
            if (newValue != null) {
              themeProvider.changeWallpaper(newValue);
              await _updateUserSetting('selectedWallpaper', newValue.name);
            }
          },
          items: wallpapers.entries.map((entry) {
            return DropdownMenuItem<WallpaperOption>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTemperatureUnitCard() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.thermostat),
        title: const Text('Temperature Unit'),
        subtitle: Text(isCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)'),
        trailing: Switch(
          value: isCelsius,
          onChanged: (value) => _toggleTemperatureUnit(),
          activeColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Personalized Alerts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Rain Alert'),
              value: rainAlert,
              onChanged: _toggleRainAlert,
            ),
            SwitchListTile(
              title: const Text('Snow Alert'),
              value: snowAlert,
              onChanged: _toggleSnowAlert,
            ),
            TextField(
              controller: _highTempController,
              decoration: const InputDecoration(
                labelText: 'High Temperature Alert (°F)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lowTempController,
              decoration: const InputDecoration(
                labelText: 'Low Temperature Alert (°F)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveTemperatureAlerts,
              child: const Text('Save Temperature Alerts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Logout'),
        onTap: _logout,
      ),
    );
  }
}
