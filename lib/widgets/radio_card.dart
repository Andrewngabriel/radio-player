import 'package:flutter/material.dart';

class RadioCard extends StatelessWidget {
  final String id;
  final String title;
  final double freq;
  final String url;
  final int index;
  final bool selected;
  final Function _selectStation;

  RadioCard(
    this.id,
    this.title,
    this.freq,
    this.url,
    this.index,
    this.selected,
    this._selectStation,
  );

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      onPressed: () => this._selectStation(this.id),
      padding: EdgeInsets.all(0),
      borderSide: (this.selected)
          ? BorderSide(color: Colors.blue, width: 2.0)
          : BorderSide(color: Colors.black12),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
//            Padding(
//              padding: const EdgeInsets.only(bottom: 5.0),
//              child: Image.network(
//                "http://db.radioline.fr/pictures/radio_045910f6d2008eb2177fd81564ec9f71/logo200.jpg?size=200",
//                height: 60,
//              ),
//            ),
            Text(
              this.title,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Text(
              this.freq.toString(),
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
