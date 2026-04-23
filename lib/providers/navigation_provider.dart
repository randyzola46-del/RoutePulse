// lib/providers/navigation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tsptw_service.dart';

// Provider pour contrôler la navigation et la localisation sur la carte
final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

class NavigationState {
  final int selectedTab;
  final LatLng? pendingLocation;
  final String? pendingAddress;
  final bool shouldZoomToLocation;

  const NavigationState({
    this.selectedTab = 0,
    this.pendingLocation,
    this.pendingAddress,
    this.shouldZoomToLocation = false,
  });

  NavigationState copyWith({
    int? selectedTab,
    LatLng? pendingLocation,
    String? pendingAddress,
    bool? shouldZoomToLocation,
  }) {
    return NavigationState(
      selectedTab: selectedTab ?? this.selectedTab,
      pendingLocation: pendingLocation ?? this.pendingLocation,
      pendingAddress: pendingAddress ?? this.pendingAddress,
      shouldZoomToLocation: shouldZoomToLocation ?? this.shouldZoomToLocation,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void goToMap({required LatLng location, required String address}) {
    state = NavigationState(
      selectedTab: 2, // Index de l'onglet Carte
      pendingLocation: location,
      pendingAddress: address,
      shouldZoomToLocation: true,
    );
  }

  void clearPendingLocation() {
    state = state.copyWith(
      pendingLocation: null,
      pendingAddress: null,
      shouldZoomToLocation: false,
    );
  }

  void setTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  void locationViewed() {
    state = state.copyWith(shouldZoomToLocation: false);
  }
}