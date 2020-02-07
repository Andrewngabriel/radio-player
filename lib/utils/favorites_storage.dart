import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/radio_station.dart';

class FavoritesStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/radioFavorites.dat');
  }

  Future<bool> writeFavorites(List<RadioStation> favoritesList) async {
    try {
      final file = await _localFile;

      print(favoritesList);
      String json = jsonEncode(favoritesList);
      print(json);
      await file.writeAsString(json, mode: FileMode.write);

      return true;
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<List<RadioStation>> readFavorites() async {
    try {
      final file = await _localFile;

      String jsonString;
      if (await file.exists()) {
        // Read the file
        jsonString = await file.readAsString();
      } else {
        jsonString = '[]';
      }

      Iterable jsonMap = jsonDecode(jsonString);

      List<RadioStation> favs = jsonMap
          .map((parsedJson) => RadioStation.fromJson(parsedJson))
          .toList();

      return favs;
    } catch (e) {
      print(e);
    }

    return List();
  }
}
