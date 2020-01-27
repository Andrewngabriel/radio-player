import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';

import '../models/radio_station.dart';

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

class _PlayerState extends State<Player> {
  AudioPlaybackState playbackState;
  Icon playPauseBtn;
  bool _buffering = false;
  String _oldId = '';

  @override
  void initState() {
    super.initState();
    connectBackgroundTask();
    PlaybackState state = AudioService.playbackState;
    displayPlaybackState(state?.basicState);
  }

  // Sets this widget state according to the current playback state.
  // This includes things like setting the appropriate icon for the button.
  void displayPlaybackState(BasicPlaybackState state) {
    if (state == BasicPlaybackState.playing) {
      playPauseBtn = Icon(Icons.pause_circle_outline);
      _buffering = false;
    } else if (state == BasicPlaybackState.paused) {
      playPauseBtn = Icon(Icons.play_circle_outline);
      _buffering = false;
    } else if (state == BasicPlaybackState.buffering) {
      _buffering = true;
    } else {
      playPauseBtn = Icon(Icons.play_circle_outline);
      _buffering = false;
    }
  }

  @override
  void didUpdateWidget(Player oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    AudioService.disconnect();
    super.dispose();
  }

  void connectBackgroundTask() async {
    await AudioService.connect();
    // If the background task hasn't been started yet, then go ahead and start it.
    if (!await AudioService.running) {
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
        print(station.url);
        await AudioService.addQueueItem(MediaItem(
          id: station.url,
          title: station.name,
          album: '${station.frequency}',
        ));
      }
    }
    // Setup listeners so that the state changes when the audio player is
    // controlled outside the GUI.
    listenForAudioPlayerStateChanges();
    listenForAudioPlayerMediaChanges();
  }

  void listenForAudioPlayerStateChanges() {
    AudioService.playbackStateStream.listen((PlaybackState state) {
      if (state == null) return;
      setState(() => this.displayPlaybackState(state?.basicState));
    });
  }

  void listenForAudioPlayerMediaChanges() {
    AudioService.currentMediaItemStream.listen((item) {
      // We store the url of the station in the 'id' field because there is
      // no other appropriate field in MediaItem to store it in.
      String itemUrl = item.id;
      if (itemUrl != widget.station.url) {
        String stationId =
            widget.stations.firstWhere((station) => station.url == itemUrl).id;
        widget.selectStation(stationId);
      }
    });
  }

  // Makes sure that the background service is currently set to play the station
  // contained in widget.station.
  Future<void> ensureServiceIsPlayingCorrectStation() async {
    // Performing this check ensures that we only tell the backend to change the
    // station if it was changed from the GUI, which ensures that we don't step
    // on any efforts to change the station from the notification.
    if (widget.station.url != _oldId) {
      await AudioService.skipToQueueItem(widget.station.url);
      _oldId = widget.station.url;
    }
  }

  void _playPause() async {
    PlaybackState state = AudioService.playbackState;
    if (state?.basicState == BasicPlaybackState.playing) {
      await AudioService.pause();
    } else {
      // Make sure the background task has selected the correct station before
      // asking it to play.
      await ensureServiceIsPlayingCorrectStation();
      await AudioService.play();
    }
  }

  void _printDebugInfo() async {
    print(await AudioService.running);
  }

  @override
  Widget build(BuildContext context) {
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
                "${widget.station.name}, ${widget.station.frequency}",
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              ),
            ),
          ),
          _buffering
              ? SpinKitChasingDots(
                  color: Colors.white,
                  size: 50.0,
                )
              : IconButton(
                  icon: this.playPauseBtn,
                  color: Colors.white,
                  iconSize: 50,
                  onPressed: this._playPause,
                  padding: EdgeInsets.only(right: 0.0),
                ),
          IconButton(
            icon: Icon(Icons.settings),
            color: Colors.white,
            iconSize: 50,
            onPressed: this._printDebugInfo,
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
  int _currentQueueIndex = 0;
  Completer _endGuard = new Completer<void>();
  bool _reloadMedia = false;

  @override
  Future<void> onStart() async {
    AudioServiceBackground.setQueue(_queue);
    setState(BasicPlaybackState.paused);
    await _endGuard.future;
    await _audioPlayer.dispose();
  }

  @override
  void onStop() async {
    await _audioPlayer.stop();
    _endGuard.complete();
  }

  @override
  void onAddQueueItem(MediaItem item) {
    _queue.add(item);
    // If this is the first item, display it in the notification.
    if (_queue.length == 1) {
      AudioServiceBackground.setMediaItem(item);
    }
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

  @override
  void onPlay() async {
    // Doing the actual loading here in the onPlay() method ensures that the
    // loading of the media will complete before play() is called.
    if (_reloadMedia) {
      _reloadMedia = false;
      // Tell the main process that the audio is buffering.
      setState(BasicPlaybackState.buffering);
      await _audioPlayer.setUrl(_queue[_currentQueueIndex].id);
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
    _reloadMedia = true;
    AudioServiceBackground.setMediaItem(_queue[_currentQueueIndex]);
    if (AudioServiceBackground.state.basicState == BasicPlaybackState.playing) {
      await _audioPlayer.pause();
      // Reload the media.
      onPlay();
    }
  }

  void setState(BasicPlaybackState state) {
    bool playing = state == BasicPlaybackState.playing;
    AudioServiceBackground.setState(controls: [
      previousControl,
      playing ? pauseControl : playControl,
      nextControl
    ], systemActions: [], basicState: state);
  }
}
