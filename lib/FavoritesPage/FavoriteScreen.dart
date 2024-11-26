import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'FavoritesProvider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  late FavoritesProvider favoritesProvider;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _editFavorite(LatLng location) async {
    TextEditingController nameController =
    TextEditingController(text: favoritesProvider.favoriteLocations[location]);

    String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Favorite Name"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: "Enter new name",
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

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        favoritesProvider.updateFavoriteName(location, newName);
      });
    }
  }

  Future<void> _deleteFavorite(LatLng location) async {
    setState(() {
      favoritesProvider.removeFavorite(location);
    });
  }

  @override
  Widget build(BuildContext context) {
    favoritesProvider = Provider.of<FavoritesProvider>(context);
    favoritesProvider.loadFavorites();

    return FutureBuilder<void>(
        future: favoritesProvider.loadFavorites(),
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Favorite Locations'),
            ),
            body: ListView.builder(
              itemCount: favoritesProvider.favoriteLocations.length,
              itemBuilder: (context, index) {
                final entry = favoritesProvider.favoriteLocations.entries.elementAt(index);
                final location = entry.key;
                final name = entry.value;

                return ListTile(
                  leading: const Icon(Icons.star, color: Colors.yellow),
                  title: Text(name),
                  subtitle: Text("Lat: ${location.latitude}, Lng: ${location.longitude}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editFavorite(location),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFavorite(location),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
    );
  }
}
