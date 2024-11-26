import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String? _mapStyle = 'dark'; // Options: 'dark', 'dark_golden', 'night'
  int _mockPingRate = 1000;

  String get mapStyle =>  (_mapStyle != null) ? _mapStyle! : 'dark';
  int get mockPingRate => _mockPingRate;

  void saveMapStyle(mapStyle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('map_style', mapStyle);
  }

  Future<void> readMapStyle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _mapStyle = prefs.getString('map_style');
  }

  void setMapStyle(String style) {
    _mapStyle = style;
    notifyListeners();

    saveMapStyle(_mapStyle);
  }

  void savePingRate(mapStyle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('mock_ping_rate', _mockPingRate);
  }

  Future<void> readPingRate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? a = prefs.getInt('mock_ping_rate');
    _mockPingRate = (a != null) ? a : _mockPingRate;
  }

  void setPingRate(int newRate) {
    _mockPingRate = newRate;
    notifyListeners();

    savePingRate(_mockPingRate);
  }
}
