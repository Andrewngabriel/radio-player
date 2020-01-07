import 'package:flutter/material.dart';

import '../config.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(
          "Favorites",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(10.0, 10.0, 10, 0.0),
        decoration: Config.backgroundGradient(),
        child: ListView(
          children: <Widget>[
            Text(
              "Favorites!",
              style: TextStyle(color: Colors.white, fontSize: 40),
            ),
          ],
        ),
      ),
    );
  }
}
