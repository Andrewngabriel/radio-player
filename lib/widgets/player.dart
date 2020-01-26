import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';

import '../models/radio_station.dart';

class Player extends StatefulWidget {
  final RadioStation station;
  final int index;

  Player({
    Key key,
    @required this.station,
    @required this.index,
  }) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  AudioPlaybackState playbackState;
  Icon playPauseBtn;
  String _oldUrl = '';
  bool _buffering = false;

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

  // Call this to send information about the current station to the
  // audio service.
  Future<void> updatePlayerMetadata() async {
    if (widget.station.url == _oldUrl) {
      // Don't update if the station hasn't changed since the last time we
      // sent information.
      return;
    }

    PlaybackState state = AudioService.playbackState;
    bool wasPlaying = state?.basicState == BasicPlaybackState.playing;
    if (wasPlaying) {
      await AudioService.pause();
    }
    // Our custom addQueueItem() handler is really a setQueueItem() function,
    // it clears the 'queue' before adding the new item, so there is only
    // ever one item in the queue at a time.
    await AudioService.addQueueItem(MediaItem(
      id: widget.station.url,
      album: '${widget.station.frequency} FM',
      title: widget.station.name,
    ));
    _oldUrl = widget.station.url;
    if (wasPlaying) {
      await AudioService.play();
    }
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
    }
    // Setup listeners so that the state changes when the audio player is
    // controlled outside the GUI.
    listenForAudioPlayerStateChanges();
  }

  void listenForAudioPlayerStateChanges() async {
    await for (PlaybackState state in AudioService.playbackStateStream) {
      if (state == null) continue;
      setState(() => this.displayPlaybackState(state?.basicState));
    }
  }

  void _playPause() async {
    PlaybackState state = AudioService.playbackState;
    if (state?.basicState == BasicPlaybackState.playing) {
      await AudioService.pause();
      setState(() => playPauseBtn = Icon(Icons.play_circle_outline));
    } else {
      // Make sure that the player has the metadata for the current station
      // before playing.
      await updatePlayerMetadata();
      await AudioService.play();
      setState(() => playPauseBtn = Icon(Icons.pause_circle_outline));
    }
  }

  void _printDebugInfo() async {
//    audioPlayer.playbackStateStream.listen((state) {}, onDone: );
    // print("playbackState: ${this.audioPlayer.playbackState}");
    print(await AudioService.running);
  }

  @override
  Widget build(BuildContext context) {
    // The widget gets rebuilt when a new station is selected. Make sure that
    // the background service has the metadata for the current station.
    updatePlayerMetadata();
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

class MyBackgroundTask extends BackgroundAudioTask {
  final _audioPlayer = AudioPlayer();
  List<MediaItem> _queue = [MediaItem(id: '', title: 'None', album: 'Radio')];
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
    await _audioPlayer.stop();
    _endGuard.complete();
  }

  @override
  void onAddQueueItem(MediaItem item) {
    if (item.id != _queue[0].id) {
      _reloadMedia = true;
    }
    _queue[0] = item;
    AudioServiceBackground.setQueue(_queue);
  }

  @override
  void onPlay() async {
    AudioServiceBackground.setState(
      controls: [pauseControl],
      systemActions: [],
      basicState: BasicPlaybackState.playing,
    );
    // Doing the actual loading here in the onPlay() method ensures that the
    // loading of the media will complete before play() is called.
    if (_reloadMedia) {
      _reloadMedia = false;
      AudioServiceBackground.setMediaItem(_queue[0]);
      // Tell the main process that the audio is buffering.
      AudioServiceBackground.setState(
          controls: [pauseControl],
          systemActions: [],
          basicState: BasicPlaybackState.buffering);
      await _audioPlayer.setUrl(_queue[0].id);
      AudioServiceBackground.setState(
          controls: [pauseControl],
          systemActions: [],
          basicState: BasicPlaybackState.playing);
    }

    _audioPlayer.play();
  }

  @override
  void onPause() async {
    AudioServiceBackground.setState(
      controls: [playControl],
      systemActions: [],
      basicState: BasicPlaybackState.paused,
    );
    await _audioPlayer.pause();
  }

  @override
  void onClick(MediaButton button) {
    // Your custom dart code to handle a media button click.
  }
}
