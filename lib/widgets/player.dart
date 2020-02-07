import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radio_player/utils/station_favorites.dart';

import '../models/radio_station.dart';

const String STREAM_TIME_OUT_ERROR = 'Error: Stream timed out.';
const int STREAM_TIME_OUT_DURATION = 15;

class Player extends StatefulWidget {
  final RadioStation station;
  final List<RadioStation> stations;
  final Function selectStation;
  final int index;

  Player({
    Key key,
    @required this.station,
    @required this.stations,
    @required this.selectStation,
    @required this.index,
  }) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> with WidgetsBindingObserver {
  bool _playing = false;
  bool _notStopped = false;
  bool _buffering = false;
  String _oldId = '';
  BuildContext _context;

  @override
  void initState() {
    super.initState();
    _setupAudioService();
    // So we can detect the app being paused / resumed.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioService.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_notStopped && !_playing) {
        AudioService.stop();
      }
    }
  }

  // Sets this widget state according to the current playback state.
  void _displayPlaybackState(BasicPlaybackState state) {
    setState(() {
      if (state == BasicPlaybackState.playing) {
        _notStopped = true;
        _playing = true;
        _buffering = false;
      } else if (state == BasicPlaybackState.paused ||
          state == BasicPlaybackState.error) {
        _notStopped = true;
        _playing = false;
        _buffering = false;
      } else if (state == BasicPlaybackState.buffering) {
        _notStopped = true;
        _playing = false;
        _buffering = true;
      } else if (state == BasicPlaybackState.stopped) {
        _notStopped = false;
        _playing = false;
        _buffering = false;
      } else {
        _notStopped = false;
        _playing = false;
        _buffering = false;
      }
    });
    if (state == BasicPlaybackState.error) {
      this._showErrorSnackbar(STREAM_TIME_OUT_ERROR);
    }
  }

  void _showErrorSnackbar(String message) {
    Scaffold.of(_context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(message)));
  }

  // Called once, when the widget first becomes visible.
  Future<void> _setupAudioService() async {
    if (AudioService.connected) {
      return;
    }
    await AudioService.connect();
    if (await AudioService.running) {
      // If the background task is already running, load the current channel
      // from the background task.
      String currentStationUrl = AudioService.currentMediaItem?.id;
      if (currentStationUrl == null) {
        widget.selectStation(widget.stations[0].url);
      } else {
        widget.selectStation(currentStationUrl);
      }
      PlaybackState state = AudioService.playbackState;
      _displayPlaybackState(state?.basicState);
    } else {
      widget.selectStation(widget.stations[0].url);
    }
    // Setup listeners so that the state changes when the audio player is
    // controlled outside the GUI.
    listenForAudioPlayerStateChanges();
    listenForAudioPlayerMediaChanges();
  }

  Future<void> _startAudioService() async {
    if (await AudioService.running) {
      return;
    }
    await AudioService.start(
      backgroundTaskEntrypoint: backgroundTaskEntryPoint,
      notificationColor: 0xFF2196f3,
      androidNotificationChannelName: 'Music Player',
      androidNotificationIcon: "mipmap/ic_launcher",
      enableQueue: true,
    );
    // Send metadata about all the stations so that the player can change
    // between stations without help from the main process.
    for (RadioStation station in widget.stations) {
      await AudioService.addQueueItem(MediaItem(
        id: station.url,
        title: station.name,
        album: '${station.frequency}',
      ));
    }
  }

  void listenForAudioPlayerStateChanges() {
    AudioService.playbackStateStream.listen((PlaybackState state) {
      if (state == null) return;
      _displayPlaybackState(state?.basicState);
    });
  }

  void listenForAudioPlayerMediaChanges() {
    AudioService.currentMediaItemStream.listen((item) {
      if (item == null) return;
      // We store the url of the station in the 'id' field because there is
      // no other appropriate field in MediaItem to store it in.
      String itemUrl = item.id;
      if (itemUrl != widget.station?.url) {
        widget.selectStation(itemUrl);
      }
    });
  }

  // Makes sure that the background service is currently set to play the station
  // contained in widget.station.
  Future<void> ensureServiceIsPlayingCorrectStation(
      {bool force = false}) async {
    if (!await AudioService.running) return;
    if (widget.station == null) return;
    // Performing this check ensures that we only tell the backend to change the
    // station if it was changed from the GUI, which ensures that we don't step
    // on any efforts to change the station from the notification.
    if (widget.station.url != _oldId || force) {
      await AudioService.skipToQueueItem(widget.station.url);
      _oldId = widget.station.url;
    }
  }

  void _playPause() async {
    if (_playing) {
      await AudioService.pause();
    } else {
      // If the background task isn't running, then start it.
      if (!await AudioService.running) {
        setState(() {
          // This way the user knows something is happening, because starting
          // the audio service will take a little while.
          _buffering = true;
        });
        await _startAudioService();
        // Force the player to change to the station.
        await ensureServiceIsPlayingCorrectStation(force: true);
      } else {
        // Make sure the background task has selected the correct station before
        // asking it to play.
        await ensureServiceIsPlayingCorrectStation();
      }
      await AudioService.play();
    }
  }

  void _stop() async {
    if (!await AudioService.running) return;
    await AudioService.stop();
    setState(() {
      _playing = false;
      _buffering = false;
    });
  }

  void _printDebugInfo() async {
    print(await AudioService.running);
  }

  @override
  Widget build(BuildContext context) {
    // We need to store the context so that we can show snackbars to the user
    // when errors occur.
    _context = context;
    // Rebuild gets called whenever the selected station is changed. Make sure
    // that the background task also knows what station we changed to.
    ensureServiceIsPlayingCorrectStation();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0.2, 1.0],
          colors: [Color(0xFF263241), Color(0xFF413f6A)],
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                "${widget.station?.name} ${(widget.station?.frequency != 0.0) ? ', ${widget.station?.frequency}' : ''}",
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              ),
            ),
          ),
          Consumer<StationFavorites>(
            builder: (context, favorites, _) => IconButton(
              icon: Icon(favorites.isFavorite(widget.station)
                  ? Icons.favorite
                  : Icons.favorite_border),
              color: Colors.red,
              iconSize: 30,
              onPressed: () => this.setState(() {
                if (favorites.isFavorite(widget.station)) {
                  favorites.removeFavorite(widget.station);
                } else {
                  favorites.addFavorite(widget.station);
                }
              }),
              padding: EdgeInsets.only(right: 15),
            ),
          ),
          _notStopped
              ? IconButton(
                  icon: Icon(Icons.stop),
                  onPressed: this._stop,
                  color: Colors.white,
                  iconSize: 36)
              : Container(),
          _buffering
              ? SpinKitRipple(
                  color: Colors.white,
                  size: 50,
                )
              : IconButton(
                  icon: Icon(_playing
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline),
                  color: Colors.white,
                  iconSize: 50,
                  onPressed: this._playPause,
                  padding: EdgeInsets.only(right: 0.0),
                ),
        ],
      ),
    );
  }
}

void backgroundTaskEntryPoint() {
  AudioServiceBackground.run(() => MyBackgroundTask());
}

MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_play_arrow',
  label: 'Play',
  action: MediaAction.play,
);
MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_pause',
  label: 'Pause',
  action: MediaAction.pause,
);
MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/ic_stop',
  label: 'Stop',
  action: MediaAction.stop,
);
MediaControl previousControl = MediaControl(
  androidIcon: 'drawable/ic_arrow_back',
  label: 'Previous Station',
  action: MediaAction.skipToPrevious,
);
MediaControl nextControl = MediaControl(
  androidIcon: 'drawable/ic_arrow_forward',
  label: 'Next Station',
  action: MediaAction.skipToNext,
);

class MyBackgroundTask extends BackgroundAudioTask {
  final _audioPlayer = AudioPlayer();
  List<MediaItem> _queue = [];
  int _currentQueueIndex = -1;
  Completer _endGuard = new Completer<void>();
  bool _reloadMedia = false;

  @override
  Future<void> onStart() async {
    AudioServiceBackground.setQueue(_queue);
    await _endGuard.future;
    await _audioPlayer.dispose();
  }

  @override
  void onStop() async {
    setState(BasicPlaybackState.stopped);
    await _audioPlayer.stop();
    _endGuard.complete();
  }

  @override
  void onAddQueueItem(MediaItem item) async {
    _queue.add(item);
    AudioServiceBackground.setQueue(_queue);
  }

  @override
  void onSkipToQueueItem(String id) async {
    int oldIndex = _currentQueueIndex;
    _currentQueueIndex = _queue.indexWhere((item) => item.id == id);
    if (oldIndex != _currentQueueIndex) {
      await onStationChange();
    }
  }

  Future<bool> _loadTrack(String url) async {
    const SUCCESS = 0;
    const INTERRUPTED = 1;
    const TIMEOUT = 2;
    var future = Future(() async {
      var duration = await _audioPlayer.setUrl(url);
      if (duration == null) {
        return INTERRUPTED;
      } else {
        return SUCCESS;
      }
    }).timeout(Duration(seconds: STREAM_TIME_OUT_DURATION),
        onTimeout: () async => TIMEOUT);
    var result = await future;
    if (result == SUCCESS) {
      return true;
    } else if (result == INTERRUPTED) {
      return false;
    } else if (result == TIMEOUT) {
      setState(BasicPlaybackState.error);
      return false;
    }
    return false;
  }

  @override
  void onPlay() async {
    // Doing the actual loading here in the onPlay() method ensures that the
    // loading of the media will complete before play() is called.
    if (_reloadMedia) {
      _reloadMedia = false;
      // Tell the main process that the audio is buffering.
      setState(BasicPlaybackState.buffering);
      var success = await _loadTrack(_queue[_currentQueueIndex].id);
      if (!success) {
        // There was a problem loading the track, don't try to play it.
        return;
      }
    }

    setState(BasicPlaybackState.playing);
    _audioPlayer.play();
  }

  @override
  void onPause() async {
    setState(BasicPlaybackState.paused);
    await _audioPlayer.pause();
  }

  @override
  void onClick(MediaButton button) {
    // Your custom dart code to handle a media button click.
  }

  @override
  void onSkipToPrevious() async {
    if (_currentQueueIndex == 0) _currentQueueIndex = _queue.length;
    _currentQueueIndex--;
    await onStationChange();
  }

  @override
  void onSkipToNext() async {
    _currentQueueIndex++;
    if (_currentQueueIndex == _queue.length) _currentQueueIndex = 0;
    await onStationChange();
  }

  Future<void> onStationChange() async {
    // This value is only -1 when an invalid request was submitted.
    if (_currentQueueIndex == -1) {
      return;
    }
    _reloadMedia = true;
    AudioServiceBackground.setMediaItem(_queue[_currentQueueIndex]);
    if (AudioServiceBackground.state.basicState == BasicPlaybackState.playing) {
      await _audioPlayer.pause();
      // Reload the media.
      onPlay();
    } else if (AudioServiceBackground.state.basicState ==
        BasicPlaybackState.buffering) {
      // Stop buffering the old media, play the new media.
      await _audioPlayer.stop();
      onPlay();
    }
  }

  void setState(BasicPlaybackState state) {
    bool playing = state == BasicPlaybackState.playing;
    AudioServiceBackground.setState(controls: [
      previousControl,
      stopControl,
      playing ? pauseControl : playControl,
      nextControl
    ], systemActions: [], basicState: state);
  }
}
