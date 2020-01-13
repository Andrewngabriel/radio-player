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
    this.favoriteStationList = favoriteStations.favoriteList;
  }

  @override
  void didUpdateWidget(FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("favorites ~ didUpdateWidget()");
    updateStations();
  }

  void updateStations() async {
    List<RadioStation> updatedStations =
        await StationList.getRefreshedStations();
    setState(() => this.favoriteStationList = updatedStations);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Config.backgroundGradient(),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: EdgeInsets.all(10.0),
        children: favoriteStationList.map((station) {
          int index = favoriteStationList.indexOf(station);
          return RadioCard(
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
