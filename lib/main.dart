import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'FavoritesPage/FavoritesProvider.dart';
import 'MapsPage/MapScreen.dart';
import 'SettingsPage/SettingsProvider.dart';
import 'SettingsPage/SettingsScreen.dart';
import 'package:genie/FavoritesPage/FavoriteScreen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    // favoritesProvider.loadFavorites();

    return FutureBuilder<void>(
        future: favoritesProvider.loadFavorites(),
        builder: (context, snapshot) {
          return MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.green[700],
            ),
            darkTheme: ThemeData.dark(),
            home: const HomeScreen(),
          );
        }
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _HomeScreenState _singleton = _HomeScreenState._internal();

  factory _HomeScreenState() {
    return _singleton;
  }

  _HomeScreenState._internal();

  int _selectedIndex = 0;
  final List<Widget> _pages = [const MapScreen(), const FavoriteScreen(), const SettingsScreen()];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Genie', style: TextStyle(color: Colors.white),),
      //   elevation: 2,
      //   backgroundColor: Colors.black,
      // ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Fav',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          )
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}




// class SettingsScreen extends StatelessWidget {
//   static final SettingsScreen _singleton = SettingsScreen._internal();
//
//   factory SettingsScreen() {
//     return _singleton;
//   }
//
//   SettingsScreen._internal();
//
//
//   // const SettingsScreen({super.key});
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text(
//         'Settings Page',
//         style: TextStyle(fontSize: 24, color: Colors.grey[700]),
//       ),
//     );
//   }
// }



