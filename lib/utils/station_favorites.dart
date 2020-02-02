import 'package:flutter/material.dart';
import 'package:radio_player/models/radio_station.dart';
import 'package:radio_player/utils/favorites_storage.dart';

class StationFavorites extends ChangeNotifier {
  static final StationFavorites _instance = StationFavorites._internal();
  FavoritesStorage storage = FavoritesStorage();
  List<RadioStation> favorites = [];

  // Singleton pattern, so that we only ever have one instance of
  // StationFavorites, shared between everything that requires it.
  factory StationFavorites() {
    return _instance;
  }

  StationFavorites._internal() {
    // Load the file once, so that all the other functions can have synchronous
    // results.
    () async {
      this.favorites = await storage.readFavorites();
    }();
  }

  List<RadioStation> readAllFavorites() {
    return this.favorites;
  }

  Future addFavorite(RadioStation station) async {
    if (!this.favorites.any((fStation) => fStation.name == station.name)) {
      this.favorites.add(station);
      notifyListeners();

      await storage.writeFavorites(this.favorites);
    }
  }

  Future removeFavorite(RadioStation station) async {
    this.favorites.removeWhere((fStation) => fStation.name == station.name);
      notifyListeners();

    await storage.writeFavorites(this.favorites);
  }

  bool isFavorite(RadioStation station) {
    return this.favorites.any((fStation) => fStation.name == station.name);
  }
}
