import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'styles.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isCelsius = true;

  void _toggleTemperatureUnit() {
    setState(() {
      isCelsius = !isCelsius;
    });
    // Save this preference to Firestore later if you want
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Temperature unit set to ${isCelsius ? "Celsius" : "Fahrenheit"}')),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Card(
              color: AppColors.primaryBlue.withOpacity(0.8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.thermostat),
                title: const Text('Temperature Unit'),
                subtitle: Text(isCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)'),
                trailing: Switch(
                  value: isCelsius,
                  onChanged: (value) => _toggleTemperatureUnit(),
                  activeColor: AppColors.secondaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: AppColors.primaryBlue.withOpacity(0.8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
