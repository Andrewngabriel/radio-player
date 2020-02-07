import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_player/utils/station_favorites.dart';

import '../models/radio_station.dart';
import '../utils/config.dart';
import '../widgets/radio_card.dart';

class FavoritesScreen extends StatelessWidget {
  final Function selectStation;

  FavoritesScreen({this.selectStation});

  @override
  Widget build(BuildContext context) {
    return Consumer<StationFavorites>(
      builder: (context, favorites, _) {
        List<Widget> children;
        List<RadioStation> favoriteStations = favorites.readAllFavorites();

        children = favoriteStations.map((station) {
          int index = favoriteStations.indexOf(station);
          return RadioCard(
            station,
            index,
            selectStation,
          );
        }).toList();
        return Container(
          decoration: Config.backgroundGradient(),
          child: ListView(padding: EdgeInsets.all(10.0), children: children),
        );
      },
    );
  }
}
