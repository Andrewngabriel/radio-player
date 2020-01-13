import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';

import '../models/radio_station.dart';
import '../models/station_list.dart';
import '../playerState.dart';
import '../utils/station_favorites.dart';

class Player extends StatefulWidget {
  final String title;
  final double freq;
  final String url;
  final int index;

  Player({
    Key key,
    @required this.title,
    @required this.freq,
    @required this.url,
    @required this.index,
  }) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> with SingleTickerProviderStateMixin {
  StationFavorites _favorites = StationFavorites();
  bool _isFavoriteStation;

  AnimationController _playBtnController;
  AudioPlayer _audioPlayer;
  AudioPlayerState _audioPlayerState;
  Duration _duration;
  Duration _position;

  PlayerState _playerState = PlayerState.STOPPED;
  StreamSubscription _durationSubscription;
  StreamSubscription _positionSubscription;
  StreamSubscription _playerCompleteSubscription;
  StreamSubscription _playerErrorSubscription;
  StreamSubscription _playerStateSubscription;

  get _isPlaying => _playerState == PlayerState.PLAYING;
  get _isPaused => _playerState == PlayerState.PAUSED;

  @override
  void initState() {
    super.initState();
    this._isFavoriteStation = false;
    this._initAudioPlayer();
    this._playBtnController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    MediaNotification.setListener('play', this._play);
    MediaNotification.setListener('pause', this._pause);
  }

  @override
  void dispose() {
    super.dispose();
    this._audioPlayer.stop();
    this._playerCompleteSubscription?.cancel();
    this._playerErrorSubscription?.cancel();
    this._playerStateSubscription?.cancel();
    this._playBtnController.dispose();
  }

  @override
  void didUpdateWidget(Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    this._isFavoriteStation = this._isFavorite();
    this._setURL();
  }

  void _setNotification() {
    if (Platform.isIOS) {
      _audioPlayer.setNotification(
        title: widget.title,
        artist: widget.freq.toString(),
      );
    }
  }

  void _playPause() async {
    if (_playerState == PlayerState.PLAYING) {
      this._stop();
      await this._playBtnController.forward().orCancel;
    } else {
      this._play();
      await this._playBtnController.reverse().orCancel;
    }
  }

  void _setURL() async {
    await _audioPlayer.setUrl(StationList.list[widget.index].url);
  }

  Future _favorite() async {
    List<RadioStation> stations = StationList.list;
    bool isInFavorites = this._favorites.isFavorite(stations[widget.index]);
    if (isInFavorites) {
      await this._favorites.removeFavorite(stations[widget.index]);
    } else {
      await this._favorites.addFavorite(stations[widget.index]);
    }
    this._isFavorite();
  }

  bool _isFavorite() {
    bool status = _favorites.isFavorite(StationList.list[widget.index]);
    setState(() => this._isFavoriteStation = status);
    return status;
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
          ],
        ),
      ),
      child: Row(
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
              (_isFavoriteStation) ? Icons.star : Icons.star_border,
              color: Colors.orange,
              size: 30,
            ),
            padding: EdgeInsets.only(top: 5, right: 20.0),
            onPressed: this._favorite,
          ),
          IconButton(
            icon: AnimatedIcon(
              icon: (_playerState == PlayerState.LOADING)
                  ? AnimatedIcons.close_menu
                  : AnimatedIcons.pause_play,
              progress: _playBtnController,
            ),
            color: Colors.white,
            iconSize: 50,
            onPressed: this._playPause,
            padding: EdgeInsets.only(right: 0.0),
          ),
        ],
      ),
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = new AudioPlayer();

    _playerCompleteSubscription =
        _audioPlayer.onPlayerCompletion.listen((event) {
      _onComplete();
      setState(() => _position = _duration);
    });

    _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.STOPPED;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      print(state);
      if (!mounted) return;
      setState(() => _audioPlayerState = state);
    });
  }

  Future<int> _play() async {
    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    final url = widget.url;
    setState(() => _playerState = PlayerState.LOADING);
    final result = await _audioPlayer.play(url, position: playPosition);
    if (result == 1) setState(() => _playerState = PlayerState.PLAYING);

    _audioPlayer.setPlaybackRate(playbackRate: 1.0);

    return result;
  }

  Future<int> _pause() async {
    final result = await _audioPlayer.pause();
    if (result == 1) setState(() => _playerState = PlayerState.PAUSED);
    return result;
  }

  Future<int> _stop() async {
    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        _playerState = PlayerState.STOPPED;
        _position = Duration();
      });
    }
    MediaNotification.hideNotification();
    return result;
  }

  void _onComplete() {
    setState(() => _playerState = PlayerState.STOPPED);
  }
}
