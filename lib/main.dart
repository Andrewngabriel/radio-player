import 'package:flutter/material.dart';

import './models/radio_station.dart';
import './models/station_list.dart';
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
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Keeps track of the array index of station array
  int _selectedStationIndex = 0;
  int _selectedPageIndex = 0;
  RadioStation _chosenStation;
  String _screenTitle = "Stations";
  StationList stationList = StationList();
  StationList _externalStationsList = StationList();

  List<RadioStation> _radioList = List<RadioStation>();
  List<RadioStation> _favoritesList = List<RadioStation>();
  List<dynamic> _screens = List<dynamic>();

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
    this._radioList = stationList.radioList;
    this._radioList[0].selected = true;
    this._chosenStation = this._radioList[0];
    _screens = [
      StationsScreen(
        stations: this._radioList,
        selectStation: this._selectStation,
      ),
      SettingsScreen(),
    ];
  }

  void _selectStation(String id) async {
    RadioStation station = this.stationList.findStation(id);
    int index = this._radioList.indexOf(station);
    if (this._selectedStationIndex != index) {
      setState(() {
        this._radioList[_selectedStationIndex].selected = false;
        this._selectedStationIndex = index;
        this._radioList[this._selectedStationIndex].selected = true;
        this._chosenStation = station;
      });
      this.refreshScreen(_selectedPageIndex);
    }
  }

  void changeScreen(BuildContext ctx, int index) {
    setState(() => _selectedPageIndex = index);
    refreshScreen(_selectedPageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(this._screenTitle, style: TextStyle(color: Colors.white)),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.share,
              color: Colors.white,
              size: 35,
            ),
            padding: EdgeInsets.only(right: 5.0),
            onPressed: null,
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
              station: _chosenStation,
              stations: _radioList,
              selectStation: this._selectStation,
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

  void refreshScreen(int index) {
    /**
     * 0 ~ StationsScreen()
     * 2 ~ SettingsScreen()
     */
    switch (index) {
      case 0:
        {
          setState(() {
            this._screenTitle = "Stations";
            _screens[0] = StationsScreen(
              stations: _radioList,
              selectStation: this._selectStation,
            );
          });
        }
        break;
      case 1:
        {
          setState(() {
            this._screenTitle = "Settings";
            _screens[1] = SettingsScreen();
          });
        }
        break;
      default:
        {
          setState(() {
            _screens = [
              StationsScreen(
                  stations: _radioList, selectStation: this._selectStation),
              SettingsScreen(),
            ];
          });
        }
        break;
    }
  }
}
