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
  final audioPlayer = AudioPlayer();
  AudioPlaybackState playbackState;

  Icon playPauseBtn;

  @override
  void initState() {
    print('initState() called!');
    super.initState();
    connectBackgroundTask();
    this.audioPlayer.setUrl(widget.station.url);
    playPauseBtn = Icon(Icons.play_circle_outline);
  }

  @override
  void didUpdateWidget(Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    this.setUrl();
  }

  @override
  void dispose() {
    print('dispose() called!');
    disposeAudioPlayer();
    AudioService.disconnect();
    super.dispose();
  }

  void connectBackgroundTask() async {
    await AudioService.connect();
  }

  void setUrl() async => await this.audioPlayer.setUrl(widget.station.url);

  void disposeAudioPlayer() async => await this.audioPlayer.dispose();

  void _playPause() async {
    AudioPlaybackState state = this.audioPlayer.playbackState;
    if (state == AudioPlaybackState.playing) {
      await this.audioPlayer.pause();
      setState(() => playPauseBtn = Icon(Icons.play_circle_outline));
    } else {
      await this.audioPlayer.play();
      AudioService.start(
        backgroundTaskEntrypoint: myBackgroundTaskEntrypoint,
        notificationColor: 0xFF2196f3,
        androidNotificationChannelName: 'Music Player',
        androidNotificationIcon: "mipmap/ic_launcher",
      );
      setState(() => playPauseBtn = Icon(Icons.pause_circle_outline));
    }
  }

  void _printDebugInfo() async {
//    audioPlayer.playbackStateStream.listen((state) {}, onDone: );
    print("playbackState: ${this.audioPlayer.playbackState}");
    print(await AudioService.running);
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

void myBackgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => MyBackgroundTask());
}

class MyBackgroundTask extends BackgroundAudioTask {
  @override
  Future<void> onStart() async {
    // Your custom dart code to start audio playback.
    // NOTE: The background audio task will shut down
    // as soon as this async function completes.
  }
  @override
  void onStop() {
    // Your custom dart code to stop audio playback.
  }
  @override
  void onPlay() {
    // Your custom dart code to resume audio playback.
  }
  @override
  void onPause() {
    // Your custom dart code to pause audio playback.
  }
  @override
  void onClick(MediaButton button) {
    // Your custom dart code to handle a media button click.
  }
}
