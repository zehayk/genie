import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ApiKeyProvider.dart';

class QueryAutocompleteSearchBar extends StatefulWidget {
  @override
  _QueryAutocompleteSearchBarState createState() =>
      _QueryAutocompleteSearchBarState();
}

class _QueryAutocompleteSearchBarState extends State<QueryAutocompleteSearchBar> {
  late final String apiKey;
  final TextEditingController _searchController = TextEditingController();
  List<String> _predictions = [];

  @override
  void initState() {
    super.initState();

    fetchApiKey();
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

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(  // results
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_predictions[index]),
                  onTap: () {
                    print('Selected: ${_predictions[index]}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );


  }
}
