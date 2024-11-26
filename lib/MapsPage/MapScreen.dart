import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_background/flutter_background.dart' as fbg;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../SettingsPage/SettingsProvider.dart';
import 'mock.dart';
import 'package:genie/ApiKeyProvider.dart';
import 'package:genie/FavoritesPage/FavoritesProvider.dart';


Position defaultPosition = Position(
  latitude: 0.0,
  longitude: 0.0,
  timestamp: DateTime.now(),
  accuracy: 0.0,
  altitude: 0.0,
  heading: 0.0,
  speed: 0.0,
  speedAccuracy: 0.0,
  altitudeAccuracy: 0.0,
  headingAccuracy: 0.0,
);


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late FavoritesProvider favoritesProvider;
  late SettingsProvider settingsProvider;

  int _elapsedSeconds = 0;
  double _currentZoom = 15.0;
  late LocationSimulator mocker;
  late GoogleMapController _mapController;
  late GoogleMap myMap;
  late String _mapStyleString;
  // late Map<LatLng, String> _favoriteLocations = {};

  LatLng? _centerPosition;
  Timer? _timer;
  BitmapDescriptor? _customMarker;

  bool _isActivated = false;
  bool _resetted = false;
  bool _loaded_map = false;

  late Position userLocation;
  late Placemark address = Placemark();

  late final String apiKey;
  List<String> _predictions = [];


  @override
  void initState() {
    super.initState();

    _initializedMap();
  }

  Future<void> _initializeLocation() async {
    await _getCurrentLocation();  // getUserLocation();
    setState(() {
      _centerPosition = LatLng(
        userLocation.latitude ?? 45.552268,
        userLocation.longitude ?? -73.857163,
      );
    });
  }

  Future<String> fetchApiKey() async {
    String? apiKey = await ApiKeyProvider.getApiKey();
    if (apiKey != null) {
      return apiKey;
    } else {
      print("Failed to retrieve API key");
      return "";
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services are disabled.");
        setState(() => userLocation = defaultPosition);
        return;
      }

      // Check for permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Location permissions are denied.");
          setState(() => userLocation = defaultPosition);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("Location permissions are permanently denied.");
        setState(() => userLocation = defaultPosition);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        userLocation = position;
      });
      var _temp = await placemarkFromCoordinates(userLocation.latitude, userLocation.longitude);
      setState(() {
        address = _temp.first;
      });

    } catch (e) {
      print("Error: $e");
      setState(() => userLocation = defaultPosition);
    }
  }

  Column QueryAutocompleteSearchBar() {
    return Column(
        children: [
          Row( // search bar
            children: [
              const Icon(Icons.search, color: Colors.white54),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  cursorColor: Colors.amber[800],
                  decoration: const InputDecoration(
                    hintText: "Search location",
                    border: InputBorder.none,
                  ),
                  onChanged: _fetchQueryPredictions,
                  // onTapOutside: _clearPredictions,
                ),
              ),
            ],
          ),
          (_predictions.length != 0) ?
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // minHeight: MediaQuery.of(context).size.height,
                maxHeight: MediaQuery.of(context).size.height/5
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  return Container(
                      decoration: BoxDecoration(
                          border: Border(
                              top: (index != 0) ? const BorderSide(color: Colors.grey, width: 1) : BorderSide.none
                          )
                  ),
                    child: ListTile(
                      splashColor: Colors.red,
                      hoverColor: Colors.blue,
                      title: Text(_predictions[index]),
                      onTap: () async {
                        // print('Selected: ${_predictions[index]}');
                        Location loc = (await locationFromAddress(_predictions[index])).first;
                        _centerMapTo(loc.latitude, loc.longitude);
                        _clearPredictions();
                      },
                    ),
                  );
                },
              ),
            ),
          )
              : const SizedBox(),
        ]
    );
  }

  Future<void> _fetchQueryPredictions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/queryautocomplete/json?input=$input&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _predictions = List<String>.from(
              data['predictions'].map((p) => p['description']),
            );
          });
        } else {
          print('Error: ${data['status']}');
        }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  void _clearPredictions() {
    setState(() {
      _predictions.clear();
    });
  }

  void _zoomIn() async {
    _currentZoom = (await _mapController.getZoomLevel()) + 1;
    _mapController.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  void _zoomOut() async {
    _currentZoom = (await _mapController.getZoomLevel()) - 1;
    _mapController.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  void _centerMap() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(
          userLocation.latitude ?? 45.552268,
          userLocation.longitude ?? -73.857163,
        ), zoom: _currentZoom),
      ),
    );
  }

  void _centerMapTo(double latitude, double longitude) {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(
          latitude,
          longitude,
        ), zoom: _currentZoom),
      ),
    );
  }

  Positioned buildToolBar() {
    return Positioned(
      top: 100,
      right: 10,
      child: Column(
        children: [
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _zoomIn,
            mini: true,
            child: Icon(Icons.add, color: Colors.amber[800]),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _zoomOut,
            mini: true,
            child: Icon(Icons.remove, color: Colors.amber[800]),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _centerMap,
            mini: true,
            child: Icon(Icons.my_location, color: Colors.amber[800]),
          ),
          SizedBox(height: 30),
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _toggleFavoriteLocation,
            mini: true,
            child: Icon((_isCenterOnFav()) ? Icons.star : Icons.star_border, color: Colors.amber[800]),
          ),
        ],
      ),
    );
  }

  Future<void> loadMapStyle(BuildContext context) async {
    favoritesProvider = Provider.of<FavoritesProvider>(context);
    settingsProvider = Provider.of<SettingsProvider>(context);

    try {
      await settingsProvider.readMapStyle();
      String mapStyle = settingsProvider.mapStyle;
      await settingsProvider.readPingRate();

      String filePath;
      String default_path = "assets/map_styles/dark.json";

      try {
        filePath = 'assets/map_styles/${mapStyle}.json';
        String styleJson = await rootBundle.loadString(filePath);
        setState(() {
          _mapStyleString = styleJson;
        });
      } catch (e) {  // if exception, just load the default style
        String styleJson = await rootBundle.loadString(default_path);
        setState(() {
          _mapStyleString = styleJson;
        });
      }

    } catch (e) {
      print('Error loading map style: $e');
    }
  }

  GoogleMap buildMyMap(BuildContext context) {
    return GoogleMap(
      zoomControlsEnabled: false,
      // myLocationButtonEnabled: false,
      initialCameraPosition: CameraPosition(
        target: _centerPosition!,
        zoom: _currentZoom,
      ),
      myLocationEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      style: _mapStyleString,
      onCameraMove: (CameraPosition position) {
        setState(() {
          _centerPosition = position.target;
        });
      },
      markers: favoritesProvider.favoriteLocations.entries
                    .map((entry) => Marker(
                  markerId: MarkerId(entry.key.toString()),
                  position: entry.key,
                  icon: _customMarker ?? BitmapDescriptor.defaultMarker, // Use generated marker
                  infoWindow: InfoWindow(title: entry.value),
                ))
                .toSet(),
    );
  }

  Future<void> _initializedMap() async {
    await _loadCustomMarker();
    await _initializeLocation();
    apiKey = await fetchApiKey();

    _loaded_map = true;
  }

  Future<void> _loadCustomMarker() async {
    final icon = await _createCustomMarkerIcon(Icons.place, Colors.red, 100);
    setState(() {
      _customMarker = icon;
    });
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon(IconData iconData, Color color, double size) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: iconData.fontFamily,
        color: color,
      ),
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  bool _isCenterOnFav() {
    return favoritesProvider.favoriteLocations.containsKey(_centerPosition);
  }

  void _toggleFavoriteLocation() async {
    final LatLng centerLocation = _centerPosition!;

    if (_isCenterOnFav()) {
      setState(() {
        favoritesProvider.removeFavorite(centerLocation);
      });
    } else {
      String? locationName = await _showNameDialog();
      if (locationName != null && locationName.isNotEmpty) {
        setState(() {
          favoritesProvider.addFavorite(centerLocation, locationName);
        });
      }
    }
  }

  Future<String?> _showNameDialog() {
    TextEditingController nameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Name this location"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: "Enter a name for this location",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without saving
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(nameController.text); // Save name
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _toggleActivation() async {
    if (_isActivated) {
      _timer?.cancel();
      if (!_resetted) {
        setState(() {
          mocker.stopUpdate();
          _resetted = true;
        });
      }
      fbg.FlutterBackground.disableBackgroundExecution();
    } else {
      await _enableBackgroundExecution();

      setState(() {
        _resetted = false;
        mocker = LocationSimulator();
      });
      mocker.updateLocation(_centerPosition!, settingsProvider.mockPingRate);

      _elapsedSeconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });
      });
    }
    setState(() {
      _isActivated = !_isActivated;
    });
  }

  Future<void> _enableBackgroundExecution() async {
    const androidConfig = fbg.FlutterBackgroundAndroidConfig(
      notificationTitle: "flutter_background example app",
      notificationText: "Background notification for keeping the example app running in the background",
      notificationImportance: fbg.AndroidNotificationImportance.normal,
      notificationIcon: fbg.AndroidResource(name: 'background_icon', defType: 'drawable'), // Default is ic_launcher from folder mipmap
    );
    await fbg.FlutterBackground.initialize(androidConfig: androidConfig);
    await fbg.FlutterBackground.enableBackgroundExecution();
  }

  @override
  void dispose() {
    _timer?.cancel();
    fbg.FlutterBackground.disableBackgroundExecution();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    loadMapStyle(context);

    if (!_loaded_map) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: _centerPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        alignment: Alignment.center,
        children: [
          Stack(
            children: [
              buildMyMap(context),
              buildToolBar(),
              Positioned(
                top: 40,
                left: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QueryAutocompleteSearchBar(),
                ),
              ),
            ],
          ),
          const Icon(
            Icons.circle,
            color: Colors.red,
            size: 10,
          ),
          // Positioned(
          //   bottom: 80,
          //   child: Container(
          //     padding: const EdgeInsets.all(8.0),
          //     color: Colors.black,
          //     child: Text(
          //       'Lat: ${_centerPosition!.latitude.toStringAsFixed(6)}, '
          //           'Lng: ${_centerPosition!.longitude.toStringAsFixed(6)}',
          //       style: const TextStyle(fontSize: 16),
          //     ),
          //   ),
          // ),
          Positioned(
            bottom: 20,
            child: Column(
              children: [
                (_isActivated) ? Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Elapsed Time: ${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ) : SizedBox.shrink(),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _toggleActivation,
                  style: TextButton.styleFrom(
                    backgroundColor: _isActivated ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    _isActivated ? 'Deactivate' : 'Activate',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}