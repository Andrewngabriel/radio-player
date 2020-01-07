import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_radio/flutter_radio.dart';

import '../playerState.dart';

class Player extends StatefulWidget {
  final String title;
  final double freq;
  final String url;
  final Function play;
  final Function pause;
  final Function stop;
  final PlayerState state;

  Player({
    Key key,
    @required this.title,
    @required this.freq,
    @required this.url,
    @required this.play,
    @required this.pause,
    @required this.stop,
    @required this.state,
  }) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  @override
  void initState() {
    super.initState();
    _audioStart();
  }

  Future<void> _audioStart() async {
    await FlutterRadio.audioStart();
  }

  @override
  void dispose() {
    FlutterRadio.stop();
    super.dispose();
  }

  Icon _playBtnIcon() {
    if (widget.state == PlayerState.PLAYING) {
      return Icon(
        Icons.pause_circle_filled,
        color: Colors.white,
        size: 50,
      );
    } else {
      return Icon(
        Icons.play_circle_outline,
        color: Colors.white,
        size: 50,
      );
    }
  }

  void _playPause() {
    if (widget.state == PlayerState.PLAYING) {
      widget.stop();
    } else {
      widget.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0.2, 1.0],
          colors: [
            Color(0xFF263241),
            Color(0xFF413f6A),
//            Color(0xFF7D3F80),
//            Color(0xFFC02F75),
//            Color(0xFFF1304C),
          ],
        ),
      ),
      child: Row(
//        mainAxisSize: MainAxisSize.min,
//        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                "${widget.title}, ${widget.freq}",
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.star_border,
              color: Colors.orange,
              size: 30,
            ),
            padding: EdgeInsets.only(top: 5, right: 20.0),
//            alignment: Alignment.bottomCenter,
            onPressed: () => widget.pause(),
          ),
          IconButton(
            icon: this._playBtnIcon(),
            onPressed: _playPause,
            padding: EdgeInsets.only(right: 0.0),
          ),
//          Expanded(
//            flex: 1,
//            child: Row(
//              crossAxisAlignment: CrossAxisAlignment.center,
//              mainAxisAlignment: MainAxisAlignment.center,
//              mainAxisSize: MainAxisSize.max,
//              children: <Widget>[
//
//              ],
//            ),
//          ),
        ],
      ),
    );
  }
}
