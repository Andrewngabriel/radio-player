import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import './radio_station.dart';
import '../utils/favorites_storage.dart';

class StationList {
  final List<String> streemaEgyptURLs = [
    "https://streema.com/radios/country/Egypt",
    "https://streema.com/radios/country/Egypt?page=2",
    "https://streema.com/radios/country/Egypt?page=3",
    "https://streema.com/radios/country/Egypt?page=4",
    "https://streema.com/radios/country/Egypt?page=5",
  ];

  final String streemaBaseURL = "http://streema.com";

  List<RadioStation> radioList = [];
  List<RadioStation> favoriteList = [];

  StationList() {
    radioList = list;
    initFavoritesList();
  }

  RadioStation findStation(String url) {
    int stationIndex = radioList.indexWhere((station) => station.url == url);
    return this.radioList[stationIndex];
  }

  Future<List> parseStreemaStationsInfo() async {
    var client = http.Client();
    List streemaStationList = [];

    try {
      for (int i = 0; i < streemaEgyptURLs.length; i++) {
        String response = await client.read(this.streemaEgyptURLs[i]);
        Document parsedRes = parse(response);
        var stations =
            parsedRes.body.querySelectorAll(".items-list")[0].children;
        for (int j = 0; j < stations.length; j++) {
          if (stations[j].attributes["title"] != null &&
              stations[j].attributes["data-url"] != null) {
            String stationTitle = stations[j]
                .attributes["title"]
                .replaceAll(new RegExp(r"Play "), '');
            String stationStreemaURL = stations[j].attributes["data-url"];
            streemaStationList.add({
              'title': stationTitle,
              'streema-data-url': stationStreemaURL,
            });
          }
        }
      }
    } finally {
      client.close();
    }
    return streemaStationList;
  }

  Future<bool> parseStreamURLs(List list) async {
    var client = http.Client();
    try {
      for (int i = 0; i < list.length; i++) {
        String url = "$streemaBaseURL${list[i]["streema-data-url"]}";
        String title = list[i]["title"];
        String response = await client.read(url);
        Document parsedRes = parse(response);
        var streamURL = parsedRes.querySelector("audio");
        if (streamURL != null &&
            streamURL.children[0].attributes["src"].isNotEmpty) {
          String url = streamURL.children[0].attributes["src"];
          addNewStation(title, url);
        }
      }
    } finally {
      client.close();
    }

    return true;
  }

  void initFavoritesList() async {
    favoriteList = await FavoritesStorage().readFavorites();
  }

  void addNewStation(String title, String url) {
    radioList.add(RadioStation(title, 0.0, url));
  }

  static Future<List<RadioStation>> getRefreshedStations() async {
    return await FavoritesStorage().readFavorites();
  }

  static List<RadioStation> list = [
    RadioStation(
      "Mix FM",
      87.8,
      "http://196.219.52.61:8000/;?type=http%26nocache=20",
    ),
    RadioStation(
      "Radio Hits",
      88.2,
      "https://audiostreaming.twesto.com/radiohits215",
    ),
    RadioStation(
      "Radio Masr",
      88.7,
      "https://streaming.radio.co/scc13a6b96/listen",
    ),
    RadioStation(
      "Mega FM",
      92.7,
      "https://audiostreaming.twesto.com/megafm214",
    ),
    RadioStation(
      "Nogoum FM",
      100.6,
      "http://ice31.securenetsystems.net/NOGOUM",
    ),
    RadioStation(
      "95 FM",
      95,
      "http://178.32.62.154:9010/;",
    ),
    RadioStation(
      "El Gouna",
      100,
      "http://82.201.132.237:8000",
    ),
    RadioStation(
      "Nile FM",
      104.2,
      "https://reach-radio.esteam.rocks/radio/8010/live.mp3",
    ),
    RadioStation(
      "Mahatet Masr",
      0.0,
      "http://radio.mahatetmasr.com/mahatetmasr",
    ),
    RadioStation(
      "El-Radio 90.90 FM",
      90.90,
      "http://9090streaming.mobtada.com/9090FMEGYPT",
    ),
    RadioStation(
      "راديو القرآن الكريم",
      98.2,
      "https://livestreaming5.onlinehorizons.net/hls-live/Qurankareem/_definst_/liveevent/livestream.m3u8",
    ),
    RadioStation(
      "Radio Masr El-Gdida",
      0.0,
      "http://streaming.radio.co:80/scc13a6b96/listen",
    ),
    RadioStation(
      "راديو مصر",
      88.7,
      "http://live.radiomasr.net:8060/RADIOMASR",
    ),
  ];
}
