import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'SettingsProvider.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? pingRate;
  late SettingsProvider settingsProvider;

  @override
  void initState() {
    super.initState();
  }

  Future<void> setup() async {
    settingsProvider.readMapStyle();
    pingRate = settingsProvider.mockPingRate;
  }

  @override
  Widget build(BuildContext context) {
    settingsProvider = Provider.of<SettingsProvider>(context);

    return FutureBuilder<void>(
        future: setup(),
        builder: (context, snapshot) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Mock Ping Rate',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    keyboardType: TextInputType.number, // Sets the numeric keyboard
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly, // Only allow digits
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Enter an integer',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      // Update the pingRate variable when the value changes
                      setState(() {
                        pingRate = int.tryParse(value);
                        if (pingRate != null) {
                          settingsProvider.setPingRate(pingRate!);
                        }
                      });
                    },
                  ),
                  const SizedBox(
                    height: 150,
                  ),
                  const Text(
                    'Select Map Style',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  RadioListTile<String>(
                    title: const Text('Dark'),
                    value: 'dark',
                    groupValue: settingsProvider.mapStyle,
                    onChanged: (value) => settingsProvider.setMapStyle(value!),// _setMapStyle(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Dark - Gold'),
                    value: 'dark_golden',
                    groupValue: settingsProvider.mapStyle,
                    onChanged: (value) => settingsProvider.setMapStyle(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Night'),
                    value: 'night',
                    groupValue: settingsProvider.mapStyle,
                    onChanged: (value) => settingsProvider.setMapStyle(value!),
                  ),
                ],
              ),
            );
          }
      );
  }
}


