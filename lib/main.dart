import 'package:flutter/material.dart';
import 'package:flutter_radio/flutter_radio.dart';

import './config.dart';
import './models/radio_station.dart';
import './models/station_list.dart';
import './playerState.dart';
import './widgets/bottom_navigation.dart';
import './widgets/player.dart';
import './widgets/radio_card.dart';

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
  int _selectedIndex = 0;
  bool _listLayoutState = false;
  PlayerState _playerState = PlayerState.STOPPED;
  StationList _externalStationsList = new StationList();
  List<RadioStation> _radioList = StationList.list;

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
    _getMoreStations();
  }

  void _selectStation(int index) async {
    if (this._selectedIndex != index) {
      _stop();
      setState(() {
        this._radioList[_selectedIndex].selected = false;
        this._selectedIndex = index;
        this._radioList[this._selectedIndex].selected = true;
      });
      _play();
    }
  }

  void _play() {
    if (_playerState != PlayerState.PLAYING) {
      try {
        FlutterRadio.play(url: this._radioList[_selectedIndex].url);
        setState(() => this._playerState = PlayerState.PLAYING);
      } catch (e) {
        print(e);
      }
    }
  }

  void _pause() {
    if (_playerState == PlayerState.PLAYING) {
      try {
        FlutterRadio.pause(url: this._radioList[_selectedIndex].url);
        setState(() => this._playerState = PlayerState.PAUSED);
      } catch (e) {
        print(e);
      }
    }
  }

  void _stop() {
    if (_playerState == PlayerState.PAUSED ||
        _playerState == PlayerState.PLAYING) {
      try {
        FlutterRadio.stop();
        setState(() => this._playerState = PlayerState.STOPPED);
      } catch (e) {
        print(e);
      }
    }
  }

  Widget _gridLayout() {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: EdgeInsets.all(10.0),
      children: _radioList.map((station) {
        int index = _radioList.indexOf(station);
        return RadioCard(
          station.name,
          station.frequency,
          station.url,
          index,
          station.selected,
          this._selectStation,
        );
      }).toList(),
    );
  }

  Widget _listLayout() {
    return ListView(
      children: _radioList.map((station) {
        int index = _radioList.indexOf(station);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: RadioCard(
            station.name,
            station.frequency,
            station.url,
            index,
            station.selected,
            this._selectStation,
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    FlutterRadio.stop();
    super.dispose();
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
              Icons.list,
              color: Colors.white,
              size: 35,
            ),
            padding: EdgeInsets.only(right: 5.0),
            onPressed: () {
              setState(() => _listLayoutState = true);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.view_column,
              color: Colors.white,
              size: 35,
            ),
            padding: EdgeInsets.only(right: 5.0),
            onPressed: () {
              setState(() => _listLayoutState = false);
            },
          ),
        ],
      ),
      body: Container(
        decoration: Config.backgroundGradient(),
        child: (_listLayoutState) ? _listLayout() : _gridLayout(),
      ),
      bottomNavigationBar: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Player(
              title: _radioList[_selectedIndex].name,
              freq: _radioList[_selectedIndex].frequency,
              url: _radioList[_selectedIndex].url,
              play: this._play,
              pause: this._pause,
              stop: this._stop,
              state: this._playerState,
            ),
            BottomNavigation(),
          ],
        ),
      ),
    );
  }
}
