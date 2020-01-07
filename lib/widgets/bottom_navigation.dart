import 'package:flutter/material.dart';
import 'package:radio_player/screens/favorites.dart';
import 'package:radio_player/screens/settings.dart';

class BottomNavigation extends StatelessWidget {
  final int _menuIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      elevation: 0,
      currentIndex: _menuIndex,
      selectedItemColor: Color(0xFFC02F75),
      unselectedItemColor: Colors.grey,
      backgroundColor: Color(0xFF263241),
      onTap: (int index) => _changeScreen(context, index),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.music_video),
          title: Text("Stations"),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.star,
            color: Colors.orange,
          ),
          title: Text("Favorites"),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings,
            color: Colors.white,
          ),
          title: Text("Settings"),
        ),
      ],
    );
  }

  void _changeScreen(BuildContext context, int index) {
    switch (index) {
      case 1:
        {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return new FavoritesScreen();
              },
            ),
          );
        }
        break;

      case 2:
        {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return new SettingsScreen();
              },
            ),
          );
        }
        break;
    }
  }
}
