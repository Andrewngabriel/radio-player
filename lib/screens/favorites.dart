import 'package:flutter/material.dart';
import 'package:radio_player/models/radio_station.dart';
import 'package:radio_player/models/station_list.dart';

import '../utils/config.dart';
import '../widgets/radio_card.dart';

class FavoritesScreen extends StatefulWidget {
  final Function selectStation;

  FavoritesScreen({@required this.selectStation});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  StationList favoriteStations = StationList();
  List<RadioStation> favoriteStationList = List<RadioStation>();

  @override
  void initState() {
    super.initState();
    StationList.getRefreshedStations().then((stations) {
      this.favoriteStationList = stations;
    });
  }

  @override
  void didUpdateWidget(FavoritesScreen oldWidget) {
    updateStations();
    super.didUpdateWidget(oldWidget);
  }

  void updateStations() {
    StationList.getRefreshedStations().then((stations) {
      setState(() => this.favoriteStationList = stations);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Config.backgroundGradient(),
      child: ListView(
        padding: EdgeInsets.all(10.0),
        children: favoriteStationList.map((station) {
          int index = favoriteStationList.indexOf(station);
          return RadioCard(
            station.id,
            station.name,
            station.frequency,
            station.url,
            index,
            station.selected,
            widget.selectStation,
          );
        }).toList(),
      ),
    );
  }
}
