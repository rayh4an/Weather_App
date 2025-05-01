import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'styles.dart';

enum WallpaperOption { defaultTheme, snow, space, lightning, water, wood }

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = AppThemes.defaultTheme;
  WallpaperOption _selectedWallpaper = WallpaperOption.defaultTheme;

  ThemeProvider() {

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadWallpaper(user);
      } else {

        _selectedWallpaper = WallpaperOption.defaultTheme;
        _currentTheme = AppThemes.defaultTheme;
        notifyListeners();
      }
    });
  }

  ThemeData get currentTheme => _currentTheme;
  WallpaperOption get selectedWallpaper => _selectedWallpaper;

  void changeWallpaper(WallpaperOption option) async {
    _selectedWallpaper = option;

    switch (option) {
      case WallpaperOption.defaultTheme:
        _currentTheme = AppThemes.defaultTheme;
        break;
      case WallpaperOption.snow:
        _currentTheme = AppThemes.snowTheme;
        break;
      case WallpaperOption.space:
        _currentTheme = AppThemes.spaceTheme;
        break;
      case WallpaperOption.lightning:
        _currentTheme = AppThemes.lightningTheme;
        break;
      case WallpaperOption.water:
        _currentTheme = AppThemes.waterTheme;
        break;
      case WallpaperOption.wood:
        _currentTheme = AppThemes.woodTheme;
        break;
    }

    notifyListeners();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'selectedWallpaper': option.name,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _loadWallpaper(User user) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (data != null && data.containsKey('selectedWallpaper')) {
      final wallpaperName = data['selectedWallpaper'] as String;

      _selectedWallpaper = WallpaperOption.values.firstWhere(
        (element) => element.name == wallpaperName,
        orElse: () => WallpaperOption.defaultTheme,
      );

      switch (_selectedWallpaper) {
        case WallpaperOption.defaultTheme:
          _currentTheme = AppThemes.defaultTheme;
          break;
        case WallpaperOption.snow:
          _currentTheme = AppThemes.snowTheme;
          break;
        case WallpaperOption.space:
          _currentTheme = AppThemes.spaceTheme;
          break;
        case WallpaperOption.lightning:
          _currentTheme = AppThemes.lightningTheme;
          break;
        case WallpaperOption.water:
          _currentTheme = AppThemes.waterTheme;
          break;
        case WallpaperOption.wood:
          _currentTheme = AppThemes.woodTheme;
          break;
      }

      notifyListeners();
    }
  }

  String? get backgroundImage {
    switch (_selectedWallpaper) {
      case WallpaperOption.snow:
        return 'assets/snowflake.jpg';
      case WallpaperOption.space:
        return 'assets/space.avif';
      case WallpaperOption.lightning:
        return 'assets/thunder.jpg';
      case WallpaperOption.water:
        return 'assets/water.jpeg';
      case WallpaperOption.wood:
        return 'assets/wood.jpg';
      default:
        return null;
    }
  }
}