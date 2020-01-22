import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:audiofileplayer/audio_system.dart';
import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:flutter/material.dart';

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

class _PlayerState extends State<Player> with SingleTickerProviderStateMixin {
  static const String replayButtonId = 'replayButtonId';
  static const String newReleasesButtonId = 'newReleasesButtonId';

  AnimationController _playBtnController;

  Audio _remoteAudio;
  bool _remoteAudioPlaying = false;
  bool _remoteAudioLoading = false;
  String _remoteErrorMessage;

  @override
  void initState() {
    print('initState() called!');
    super.initState();
    AudioSystem.instance.addMediaEventListener(_mediaEventListener);
    this._loadRemoteAudio();
  }

  @override
  void dispose() {
    print('dispose() called!');
    AudioSystem.instance.removeMediaEventListener(_mediaEventListener);
    if (_remoteAudioPlaying) _remoteAudio.pause();
    if (_remoteAudio != null) _remoteAudio.dispose();
    super.dispose();
  }

  void _loadRemoteAudio() {
    _remoteErrorMessage = null;
    _remoteAudioLoading = true;
    _remoteAudio = Audio.loadFromRemoteUrl(
      widget.station.url,
      playInBackground: true,
      onDuration: (duration) => setState(() => _remoteAudioLoading = false),
      onError: (String message) => setState(() {
        print("inside onError()");
        print(message);
        _remoteErrorMessage = message;
//        _remoteAudio.dispose();
//        _remoteAudio = null;
        _remoteAudioPlaying = false;
        _remoteAudioLoading = false;
      }),
    );
  }

  Future<void> _resumeRemoteAudio() async {
    _remoteAudio.resume();
    setState(() => _remoteAudioPlaying = true);

    final Uint8List imageBytes = await generateImageBytes();
    AudioSystem.instance.setMetadata(AudioMetadata(
      title: "Great title",
      artist: "Great artist",
      album: "Great album",
      genre: "Great genre",
      durationSeconds: 0,
      artBytes: imageBytes,
    ));

    AudioSystem.instance.setAndroidNotificationButtons(<dynamic>[
      AndroidMediaButtonType.pause,
      AndroidMediaButtonType.stop,
      const AndroidCustomMediaButton(
          'replay', replayButtonId, 'ic_replay_black_36dp')
    ], androidCompactIndices: <int>[
      0
    ]);

    AudioSystem.instance.setSupportedMediaActions(<MediaActionType>{
      MediaActionType.playPause,
      MediaActionType.pause,
    }, skipIntervalSeconds: 30);
  }

  void _pauseRemoteAudio() {
    _remoteAudio.pause();
    setState(() => _remoteAudioPlaying = false);

    AudioSystem.instance.setAndroidNotificationButtons(<dynamic>[
      AndroidMediaButtonType.play,
      AndroidMediaButtonType.stop,
      const AndroidCustomMediaButton(
          'new releases', newReleasesButtonId, 'ic_new_releases_black_36dp'),
    ], androidCompactIndices: <int>[
      0
    ]);

    AudioSystem.instance.setSupportedMediaActions(<MediaActionType>{
      MediaActionType.playPause,
      MediaActionType.play,
    });
  }

  void _stopRemoteAudio() {
    _remoteAudio.pause();
    setState(() => _remoteAudioPlaying = false);
    AudioSystem.instance.stopBackgroundDisplay();
  }

  void _playPause() {
    if (_remoteAudioPlaying) {
      this._pauseRemoteAudio();
    } else {
      _remoteAudio.resume();
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
            icon: Icon(Icons.play_circle_outline),
            color: Colors.white,
            iconSize: 50,
            onPressed: this._playPause,
            padding: EdgeInsets.only(right: 0.0),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            color: Colors.white,
            iconSize: 50,
            onPressed: () {
              print(_remoteAudio);
              print("_remoteAudioPlaying: $_remoteAudioPlaying");
              print("_remoteAudioLoading: $_remoteAudioLoading");
            },
            padding: EdgeInsets.only(right: 0.0),
          ),
        ],
      ),
    );
  }

  void _mediaEventListener(MediaEvent mediaEvent) {
    print('App received media event of type: ${mediaEvent.type}');
    final MediaActionType type = mediaEvent.type;
    if (type == MediaActionType.play) {
      _resumeRemoteAudio();
    } else if (type == MediaActionType.pause) {
      _pauseRemoteAudio();
    } else if (type == MediaActionType.playPause) {
      _remoteAudioPlaying ? _pauseRemoteAudio() : _resumeRemoteAudio();
    } else if (type == MediaActionType.stop) {
      _stopRemoteAudio();
    } else if (type == MediaActionType.custom) {
      if (mediaEvent.customEventId == replayButtonId) {
        _remoteAudio.play();
        AudioSystem.instance.setPlaybackState(true, 0.0);
      } else if (mediaEvent.customEventId == newReleasesButtonId) {
        print('New-releases button is not implemented in this exampe app.');
      }
    }
  }

  static Future<Uint8List> generateImageBytes() async {
    // Random color generation methods: pick contrasting hues.
    final Random random = Random();
    final double bgHue = random.nextDouble() * 360;
    final double fgHue = (bgHue + 180.0) % 360;
    final HSLColor bgHslColor =
        HSLColor.fromAHSL(1.0, bgHue, random.nextDouble() * .5 + .5, .5);
    final HSLColor fgHslColor =
        HSLColor.fromAHSL(1.0, fgHue, random.nextDouble() * .5 + .5, .5);

    final Size size = const Size(200.0, 200.0);
    final Offset center = const Offset(100.0, 100.0);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Rect rect = Offset.zero & size;
    final Canvas canvas = Canvas(recorder, rect);
    final Paint bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = bgHslColor.toColor();
    final Paint fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = fgHslColor.toColor()
      ..strokeWidth = 8;
    // Draw background color.
    canvas.drawRect(rect, bgPaint);
    // Draw 5 inset squares around the center.
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(
          Rect.fromCenter(center: center, width: i * 40.0, height: i * 40.0),
          fgPaint);
    }
    // Render to image, then compress to PNG ByteData, then return as Uint8List.
    final ui.Image image = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    final ByteData encodedImageData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return encodedImageData.buffer.asUint8List();
  }
}
