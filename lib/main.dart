import 'package:flutter/material.dart';

import './models/radio_station.dart';
import './models/station_list.dart';
import './screens/favorites.dart';
import './screens/settings.dart';
import './screens/stations.dart';
import './widgets/bottom_navigation.dart';
import './widgets/player.dart';
import 'utils/config.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Config.title,
      theme: Config.themeOptions(context),
      home: MyHomePage(),
      routes: Config.navigationRoutes(context),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedStationIndex = 0;
  int _selectedPageIndex = 0;
  StationList _externalStationsList = StationList();
  List<RadioStation> _radioList = StationList.list;
  List _screens;

  _getMoreStations() {
    _externalStationsList.parseStreemaStationsInfo().then((stationsList) {
      _externalStationsList.parseStreamURLs(stationsList).then((stationValues) {
        setState(() {
          _radioList = _radioList + _externalStationsList.radioList;
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
//    _getMoreStations();
    _screens = [
      StationsScreen(stations: _radioList, selectStation: this._selectStation),
      FavoritesScreen(selectStation: _selectStation),
      SettingsScreen(),
    ];
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _selectStation(int index) async {
    print("Homepage ~ _selectStation()");
    if (this._selectedStationIndex != index) {
      setState(() {
        this._radioList[_selectedStationIndex].selected = false;
        this._selectedStationIndex = index;
        this._radioList[this._selectedStationIndex].selected = true;
        refreshHome();
      });
    }
  }

  void refreshHome() {
    _screens[0] = StationsScreen(
        stations: _radioList, selectStation: this._selectStation);
  }

  void changeScreen(BuildContext ctx, int index) {
    setState(() => _selectedPageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text("Stations", style: TextStyle(color: Colors.white)),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.share,
              color: Colors.white,
              size: 35,
            ),
            padding: EdgeInsets.only(right: 5.0),
            onPressed: () {},
          ),
        ],
      ),
      body: this._screens[this._selectedPageIndex],
      bottomNavigationBar: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Player(
              title: _radioList[_selectedStationIndex].name,
              freq: _radioList[_selectedStationIndex].frequency,
              url: _radioList[_selectedStationIndex].url,
              index: _selectedStationIndex,
            ),
            BottomNavigation(
              changeScreen: this.changeScreen,
              menuIndex: this._selectedPageIndex,
            ),
          ],
        ),
      ),
    );
  }
}
