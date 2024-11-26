import 'dart:async';
import 'package:fluttermocklocation/fluttermocklocation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class LocationSimulator {
  bool _error = false;
  String _positionUpdated = '';
  String _errorString = '';
  final _fluttermocklocationPlugin = Fluttermocklocation();

  late StreamSubscription<Map<String, double>> update_func;

  bool _stopped = true;


  LocationSimulator() {
    update_func = _fluttermocklocationPlugin.locationUpdates.listen((locationData) {
      // Get the current timestamp
      final DateTime now = DateTime.now();
      final String formattedTimestamp =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      // Format the position string
      final String positionString = 'latitude: ${locationData['latitude']}\n'
          'longitude: ${locationData['longitude']}\n'
          'altitude: ${locationData['altitude']}\n'
          'timestamp: $formattedTimestamp';

      // Update the position with the formatted string
      _positionUpdated = positionString;

      print(_positionUpdated);
    });
  }

  void pauseListen() {
    //update_func.pause();
  }

  void stopUpdate() async {
    _stopped = true;
    //update_func.cancel();

    await Fluttermocklocation().stopMockLocation();
  }

  void dispose() {
  }

  void updateLocation(LatLng latLng, int pingRate) async {
    try {
      _error = false;
      _errorString = '';

      final double latitude = latLng.latitude;
      final double longitude = latLng.longitude;
      final double altitude = 0.0;

      final int delay = pingRate; // Default was 5000 ms

      try {
        await Fluttermocklocation().updateMockLocation(
          latitude,
          longitude,
          altitude: altitude,
          delay: delay,
        );
        print(
            "Mock location updated: $latitude, $longitude, $altitude with delay $delay ms");

        _stopped = false;
      } catch (e) {
        print("Error updating the location: $e");
        _errorString =
        'To use this application, please enable Developer Options on your Android device.\n\nWithin Developer Options select\n\n"Select mock location app"\n\nand choose this app.';
        _error = true;
      }
    } catch (e) {
      _errorString = 'Invalid latitude, longitude, or delay.';
      _error = true;
    }
  }
}