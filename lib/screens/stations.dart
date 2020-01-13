import 'package:flutter/material.dart';

import '../models/radio_station.dart';
import '../utils/config.dart';
import '../widgets/radio_card.dart';

class StationsScreen extends StatelessWidget {
  final List<RadioStation> stations;
  final Function selectStation;

  StationsScreen({this.stations, this.selectStation});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Config.backgroundGradient(),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: EdgeInsets.all(10.0),
        children: this.stations.map((station) {
          int index = this.stations.indexOf(station);
          return RadioCard(
            station.name,
            station.frequency,
            station.url,
            index,
            station.selected,
            this.selectStation,
          );
        }).toList(),
      ),
    );
  }
}
