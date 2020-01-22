import 'package:flutter/material.dart';

import '../utils/config.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Config.backgroundGradient(),
      child: ListView(
        padding: EdgeInsets.all(10.0),
        children: <Widget>[
          Card(
            child: Text("Privacy Policy"),
          ),
        ],
      ),
    );
  }
}
