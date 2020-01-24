import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    print('initState() called!');
    super.initState();
    connectBackgroundTask();
    PlaybackState state = AudioService.playbackState;
    if (state?.basicState == BasicPlaybackState.playing) {
      playPauseBtn = Icon(Icons.pause_circle_outline);
    } else {
      playPauseBtn = Icon(Icons.play_circle_outline);
    }
  }

  @override
  void didUpdateWidget(Player oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    print('dispose() called!');
    AudioService.disconnect();
    super.dispose();
  }

  Future<void> updatePlayerMetadata() async {
    if (widget.station.url == _oldUrl) {
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
      album: 'Radio',
      title: widget.station.name,
    ));
    _oldUrl = widget.station.url;
    if (wasPlaying) {
      await AudioService.play();
    }
  }

  void connectBackgroundTask() async {
    await AudioService.connect();
    if (!await AudioService.running) {
      bool success = await AudioService.start(
        backgroundTaskEntrypoint: backgroundTaskEntryPoint,
        notificationColor: 0xFF2196f3,
        androidNotificationChannelName: 'Music Player',
        androidNotificationIcon: "mipmap/ic_launcher",
        enableQueue: true,
      );
      print('Launching background task: Successful? $success');
    }
  }

  void _playPause() async {
    PlaybackState state = AudioService.playbackState;
    if (state?.basicState == BasicPlaybackState.playing) {
      await AudioService.pause();
      setState(() => playPauseBtn = Icon(Icons.play_circle_outline));
    } else {
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
          IconButton(
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
  List<MediaItem> _queue = [MediaItem(
    id: '',
    title: 'None',
    album: 'Radio'
  )];
  Completer _endGuard = new Completer<void>();
  bool _reloadMedia = false;

  @override
  Future<void> onStart() async {
    print('we starting');
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
    if (_reloadMedia) {
      _reloadMedia = false;
      AudioServiceBackground.setMediaItem(_queue[0]);
      await _audioPlayer.setUrl(_queue[0].id);
    }
    await _audioPlayer.play();
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

