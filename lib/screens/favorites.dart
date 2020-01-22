import 'package:flutter/material.dart';
import 'package:radio_player/utils/station_favorites.dart';

import '../models/radio_station.dart';
import '../utils/config.dart';
import '../widgets/radio_card.dart';

class FavoritesScreen extends StatelessWidget {
  final Function selectStation;

  FavoritesScreen({this.selectStation});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RadioStation>>(
      future: StationFavorites().readAllFavorites(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        List<Widget> children;
        List<RadioStation> favoriteStations = snapshot.data;

        if (snapshot.hasData) {
          children = favoriteStations.map((station) {
            int index = favoriteStations.indexOf(station);
            return RadioCard(
              station.id,
              station.name,
              station.frequency,
              station.url,
              index,
              station.selected,
              this.selectStation,
            );
          }).toList();
        } else if (snapshot.hasError) {
          children = <Widget>[
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Error: ${snapshot.error}'),
            )
          ];
        } else {
          children = [
            SizedBox(
              child: CircularProgressIndicator(),
              width: 60,
              height: 60,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Awaiting result...'),
            )
          ];
        }
        return Container(
          decoration: Config.backgroundGradient(),
          child: ListView(padding: EdgeInsets.all(10.0), children: children),
        );
      },
    );
  }
}
