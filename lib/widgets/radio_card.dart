import 'package:flutter/material.dart';
import 'package:radio_player/models/radio_station.dart';
import 'package:radio_player/utils/favorites_storage.dart';
import 'package:radio_player/utils/station_favorites.dart';

class RadioCard extends StatefulWidget {
  final RadioStation station;
  final int index;
  final Function _selectStation;

  RadioCard(
    this.station,
    this.index,
    this._selectStation,
  );

  @override
  _RadioCardState createState() {
    return _RadioCardState();
  }
}

class _RadioCardState extends State<RadioCard> {
  @override
  Widget build(BuildContext context) {
    return OutlineButton(
        onPressed: () => widget._selectStation(widget.station.id),
        padding: EdgeInsets.all(0),
        borderSide: (widget.station.selected)
            ? BorderSide(color: Colors.blue, width: 2.0)
            : BorderSide(color: Colors.black12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    widget.station.name,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.station.frequency.toString(),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(0.0),
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: Icon(
                  StationFavorites().isFavorite(widget.station)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.white,
                ),
                onPressed: () => this.setState(() {
                  if (StationFavorites().isFavorite(widget.station)) {
                    StationFavorites().removeFavorite(widget.station);
                  } else {
                    StationFavorites().addFavorite(widget.station);
                  }
                }),
              ),
            )
          ],
        ));
  }
}
