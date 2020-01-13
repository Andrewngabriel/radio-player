class RadioStation {
  String name;
  String url;
  double frequency;
  bool selected = false;

  RadioStation(this.name, this.frequency, this.url);

  factory RadioStation.fromJson(Map<String, dynamic> parsedJson) {
    return RadioStation(
      parsedJson['name'],
      parsedJson['freq'],
      parsedJson['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': this.name,
      'freq': this.frequency,
      'url': this.url,
    };
  }
}
