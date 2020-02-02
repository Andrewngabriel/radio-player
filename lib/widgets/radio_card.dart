import 'package:flutter/material.dart';
import 'package:radio_player/models/radio_station.dart';

class RadioCard extends StatelessWidget {
  final RadioStation station;
  final int index;
  final Function _selectStation;

  RadioCard(
    this.station,
    this.index,
    this._selectStation,
  );

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      onPressed: () => this._selectStation(this.station.url),
      padding: EdgeInsets.all(0),
      borderSide: (this.station.selected)
          ? BorderSide(color: Colors.blue, width: 2.0)
          : BorderSide(color: Colors.black12),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              this.station.name,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Text(
              this.station.frequency.toString(),
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
