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
      'BBC Arabic',
      0.0,
      'http://bbcwssc.ic.llnwd.net/stream/bbcwssc_mp1_ws-araba',
    ),
    RadioStation(
        "Nogoum FM", 100.6, "http://ice31.securenetsystems.net/NOGOUM"),
    RadioStation(
      'Al Jazeera Arabic',
      0.0,
      'http://aljazeera-ara-apple-live.adaptive.level3.net/apple/aljazeera/arabic/radioaudio.m3u8',
    ),
    RadioStation('Rotana FM', 88.0, 'http://philae.shoutca.st:8114/stream/;'),
    RadioStation('90s FM', 0.0, 'http://64.150.176.192:8276/;'),
    RadioStation("El Gouna", 100, "http://82.201.132.237:8000"),
    RadioStation('TIBA Radio', 0.0, 'http://s1.voscast.com:10026/;'),
    RadioStation(
      "Mega FM",
      92.7,
      "https://audiostreaming.twesto.com/megafm214",
    ),
    RadioStation(
      "El-Radio 90.90 FM",
      90.90,
      "http://9090streaming.mobtada.com/9090FMEGYPT",
    ),
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
      "Mahatet Masr",
      0.0,
      "http://radio.mahatetmasr.com/mahatetmasr",
    ),
    RadioStation(
      'Monte Carlo Doualiya',
      93.4,
      'https://montecarlodoualiya128k.ice.infomaniak.ch/mc-doualiya.mp3',
    ),
    RadioStation(
      'BetterLife Radio',
      0.0,
      'http://stream.radiojar.com/8m2a8m9ymy5tv',
    ),
    RadioStation('محطة مصر', 0.0, 'http://listen.mahatetmasr.com/;'),
    RadioStation("اف ام شعبي", 95.0, "http://178.32.62.154:9010/;"),
    RadioStation('نغم اف ام', 105.3, 'https://ahmsamir.radioca.st/stream/;'),
    RadioStation(
      "Radio Masr",
      88.7,
      "https://streaming.radio.co/scc13a6b96/listen",
    ),
    RadioStation(
      "Radio Masr El-Gdida",
      0.0,
      "http://streaming.radio.co:80/scc13a6b96/listen",
    ),
    RadioStation(
      "Nile FM",
      104.2,
      "http://ice31.securenetsystems.net/NILE",
    ),
    RadioStation('صوت شباب مصر', 0.0, 'http://www.egonair.com:8010/;'),
    RadioStation(
      "راديو القرآن الكريم",
      98.2,
      "https://livestreaming5.onlinehorizons.net/hls-live/Qurankareem/_definst_/liveevent/livestream.m3u8",
    ),
    RadioStation('راديو معاك', 0.0, 'http://radioma3ak.com:8000/;'),
    RadioStation(
      'راديو صوتك',
      0.0,
      'http://serv02.streamsfortheworld.com:8000/radiosotak_hi',
    ),
    RadioStation(
      "راديو مصر",
      88.7,
      "http://live.radiomasr.net:8060/RADIOMASR",
    ),
    RadioStation('Radio Eltekia', 0.0, 'http://173.249.31.198:8000/stream/;'),
    RadioStation('راديو موجة', 0.0, 'http://eu4.fastcast4u.com:5458/;'),
    RadioStation('Radio Bridge', 0.0, 'http://213.136.85.197:9320/stream/;'),
  ];
}
