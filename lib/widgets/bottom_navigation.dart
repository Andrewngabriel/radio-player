import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int menuIndex;
  final Function changeScreen;

  BottomNavigation({this.menuIndex, this.changeScreen});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      elevation: 0,
      currentIndex: menuIndex,
      selectedItemColor: Color(0xFFC02F75),
      unselectedItemColor: Colors.grey,
      backgroundColor: Color(0xFF263241),
      onTap: (int index) => this.changeScreen(context, index),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.music_video),
          title: Text("Stations"),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
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
}
