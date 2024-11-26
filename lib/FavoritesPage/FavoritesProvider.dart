import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  Map<LatLng, String> _favoriteLocations = {};

  // Getter to retrieve favorite locations
  Map<LatLng, String> get favoriteLocations => _favoriteLocations;


  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert _favoriteLocations to JSON
    final favoriteList = _favoriteLocations.entries.map((entry) {
      return {
        'latitude': entry.key.latitude,
        'longitude': entry.key.longitude,
        'name': entry.value,
      };
    }).toList();
    final jsonString = jsonEncode(favoriteList);
    await prefs.setString('favorite_locations', jsonString);
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('favorite_locations');
    if (jsonString != null) {
      final favoriteList = jsonDecode(jsonString) as List<dynamic>;

      _favoriteLocations = {
        for (var item in favoriteList)
          LatLng(item['latitude'], item['longitude']): item['name']
      };
    }
  }

  void addFavorite(LatLng location, String name) {
    _favoriteLocations[location] = name;

    saveFavorites();
    notifyListeners();
  }

  // Update the name of an existing favorite location
  void updateFavoriteName(LatLng location, String newName) {
    if (_favoriteLocations.containsKey(location)) {
      _favoriteLocations[location] = newName;

      saveFavorites();
      notifyListeners();
    }
  }

  // Remove a favorite location
  void removeFavorite(LatLng location) {
    _favoriteLocations.remove(location);

    saveFavorites();
    notifyListeners();
  }
}

