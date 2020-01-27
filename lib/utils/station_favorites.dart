import 'package:radio_player/models/radio_station.dart';
import 'package:radio_player/utils/favorites_storage.dart';

class StationFavorites {
  static final StationFavorites _instance = StationFavorites._internal();
  FavoritesStorage storage = FavoritesStorage();
  List<RadioStation> favorites = [];

  // Singleton pattern, so that we only ever have one instance of
  // StationFavorites, shared between everything that requires it.
  factory StationFavorites() {
    return _instance;
  }

  StationFavorites._internal() {
    // Do this so that if we try adding a favorite before reading a favorite, 
    // we still have an accurate list to go off of.
    readAllFavorites();
  }

  Future<List<RadioStation>> readAllFavorites() async {
    this.favorites = await storage.readFavorites();
    return this.favorites;
  }

  Future addFavorite(RadioStation station) async {
    if (!this.favorites.any((fStation) => fStation.name == station.name)) {
      this.favorites.add(station);

      await storage.writeFavorites(this.favorites);
    }
  }

  Future removeFavorite(RadioStation station) async {
    this.favorites.removeWhere((fStation) => fStation.name == station.name);

    await storage.writeFavorites(this.favorites);
  }

  bool isFavorite(RadioStation station) {
    return this.favorites.any((fStation) => fStation.name == station.name);
  }
}
