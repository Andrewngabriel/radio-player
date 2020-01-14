import 'package:uuid/uuid.dart';

var uuid = Uuid();

class RadioStation {
  String id;
  String name;
  String url;
  double frequency;
  bool selected = false;

  RadioStation(String name, double freq, String url) {
    this.id = uuid.v1();
    this.name = name;
    this.frequency = freq;
    this.url = url;
  }

  RadioStation.withUuid(String id, String name, double freq, String url) {
    this.id = id;
    this.name = name;
    this.frequency = freq;
    this.url = url;
  }

  factory RadioStation.fromJson(Map<String, dynamic> parsedJson) {
    return RadioStation.withUuid(
      parsedJson['id'],
      parsedJson['name'],
      parsedJson['freq'],
      parsedJson['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': this.id,
      'name': this.name,
      'freq': this.frequency,
      'url': this.url,
    };
  }
}
