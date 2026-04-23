// lib/providers/carte_controller_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider pour partager le CarteController
final carteControllerProvider = Provider<CarteController>((ref) {
  throw UnimplementedError('Doit être initialisé dans MainScaffold');
});

// Controller pour communiquer avec la carte
class CarteController extends ChangeNotifier {
  LatLngForMap? _selectedLocation;

  LatLngForMap? get selectedLocation => _selectedLocation;

  void showLocation(double lat, double lng, String address) {
    _selectedLocation = LatLngForMap(lat: lat, lng: lng, address: address);
    notifyListeners();
  }

  void clearSelected() {
    _selectedLocation = null;
    notifyListeners();
  }
}

class LatLngForMap {
  final double lat;
  final double lng;
  final String address;

  LatLngForMap({required this.lat, required this.lng, required this.address});
}