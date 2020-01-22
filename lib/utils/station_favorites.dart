import 'package:radio_player/models/radio_station.dart';
import 'package:radio_player/utils/favorites_storage.dart';

class StationFavorites {
  FavoritesStorage storage = FavoritesStorage();
  List<RadioStation> favorites = [];

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
