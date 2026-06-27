import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Cached coords + permission status for the marketplace "Near me" filter.
/// Mirrors the website's useGeolocation hook.
class GeolocationState {
  final double? lat;
  final double? lng;
  final GeolocationStatus status;

  const GeolocationState({
    this.lat,
    this.lng,
    this.status = GeolocationStatus.prompt,
  });

  bool get hasCoords => lat != null && lng != null;

  GeolocationState copyWith({
    double? lat,
    double? lng,
    GeolocationStatus? status,
    bool clearCoords = false,
  }) => GeolocationState(
    lat: clearCoords ? null : (lat ?? this.lat),
    lng: clearCoords ? null : (lng ?? this.lng),
    status: status ?? this.status,
  );
}

enum GeolocationStatus { prompt, requesting, granted, denied, unsupported }

class GeolocationNotifier extends StateNotifier<GeolocationState> {
  GeolocationNotifier() : super(const GeolocationState());

  double _roughCoordinate(double value) => (value * 10).roundToDouble() / 10;

  Future<void> request() async {
    state = state.copyWith(status: GeolocationStatus.requesting);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(status: GeolocationStatus.denied);
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      state = state.copyWith(status: GeolocationStatus.denied);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      state = GeolocationState(
        lat: _roughCoordinate(pos.latitude),
        lng: _roughCoordinate(pos.longitude),
        status: GeolocationStatus.granted,
      );
    } catch (_) {
      state = state.copyWith(status: GeolocationStatus.denied);
    }
  }

  void clear() {
    state = state.copyWith(clearCoords: true, status: GeolocationStatus.prompt);
  }
}

final geolocationProvider =
    StateNotifierProvider<GeolocationNotifier, GeolocationState>(
      (ref) => GeolocationNotifier(),
    );

/// Haversine distance in kilometres between two lat/lng pairs.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final l1 = lat1 * math.pi / 180;
  final l2 = lat2 * math.pi / 180;
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(l1) * math.cos(l2) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}
