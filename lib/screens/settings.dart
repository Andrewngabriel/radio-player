import 'package:flutter/material.dart';

import '../utils/config.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Config.backgroundGradient(),
      child: GridView.count(
        crossAxisCount: 1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: EdgeInsets.all(10.0),
        children: <Widget>[
          Text("Hello!"),
        ],
      ),
    );
  }
}
