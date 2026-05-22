import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../backend/services/location_service.dart';
import '../../backend/services/route_optimization_service.dart';
import '../../backend/firebase/firebase_models.dart';
import 'dart:async';

class TrackingState {
  final List<LiveLocation> activeBuses;
  final geo.Position? currentPosition;
  final Map<String, double> busEtas; // busId -> ETA in minutes
  final bool isTrackingUser;
  final String? error;

  TrackingState({
    this.activeBuses = const [],
    this.currentPosition,
    this.busEtas = const {},
    this.isTrackingUser = false,
    this.error,
  });

  TrackingState copyWith({
    List<LiveLocation>? activeBuses,
    geo.Position? currentPosition,
    Map<String, double>? busEtas,
    bool? isTrackingUser,
    String? error,
  }) {
    return TrackingState(
      activeBuses: activeBuses ?? this.activeBuses,
      currentPosition: currentPosition ?? this.currentPosition,
      busEtas: busEtas ?? this.busEtas,
      isTrackingUser: isTrackingUser ?? this.isTrackingUser,
      error: error ?? this.error,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final LocationService _locationService = LocationService();
  final RouteOptimizationService _routeService = RouteOptimizationService();
  StreamSubscription? _userLocationSubscription;
  StreamSubscription? _busLocationsSubscription;

  TrackingNotifier() : super(TrackingState()) {
    _initBusTracking();
  }

  void _initBusTracking() {
    // Stream active buses from Firestore live_locations collection
    _busLocationsSubscription = _locationService.trackBusLocation('all_buses')
        .handleError((e) {
          state = state.copyWith(error: 'Bus locations streaming error: $e');
        })
        .listen((_) {}); // LocationService.trackBusLocation streams per busId, let's write a generic listener

    // Alternatively, stream all live locations directly
    // Let's hook into Firebase live_locations collection stream
    // Using simple firestore snapshots for all active buses
    _busLocationsSubscription = FirebaseLocationStreamHelper.streamActiveBuses()
        .listen((buses) {
          state = state.copyWith(activeBuses: buses);
          _calculateAllEtas();
        }, onError: (e) {
          state = state.copyWith(error: e.toString());
        });
  }

  Future<void> startTrackingUser() async {
    if (state.isTrackingUser) return;

    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(error: 'Location services are disabled');
      return;
    }

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        state = state.copyWith(error: 'Location permissions are denied');
        return;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      state = state.copyWith(error: 'Location permissions are permanently denied');
      return;
    }

    state = state.copyWith(isTrackingUser: true);

    _userLocationSubscription = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((geo.Position position) {
      state = state.copyWith(currentPosition: position);
      _calculateAllEtas();
    }, onError: (e) {
      state = state.copyWith(error: e.toString());
    });
  }

  void stopTrackingUser() {
    _userLocationSubscription?.cancel();
    state = state.copyWith(isTrackingUser: false, currentPosition: null);
  }

  void _calculateAllEtas() async {
    if (state.currentPosition == null || state.activeBuses.isEmpty) return;

    final etas = <String, double>{};
    for (var bus in state.activeBuses) {
      final eta = await _locationService.calculateETA(
        bus.latitude,
        bus.longitude,
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
      );
      etas[bus.entityId] = eta;
    }
    state = state.copyWith(busEtas: etas);
  }

  @override
  void dispose() {
    _userLocationSubscription?.cancel();
    _busLocationsSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}

// Helper class to stream live locations of type 'bus'
class FirebaseLocationStreamHelper {
  static Stream<List<LiveLocation>> streamActiveBuses() {
    final firestore = FirebaseLocationStreamHelper._firestore;
    return firestore
        .collection('live_locations')
        .where('entityType', isEqualTo: 'bus')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LiveLocation.fromMap(doc.data()))
              .toList();
        });
  }

  static get _firestore => FirebaseLocationStreamHelper._instance ??= FirebaseLocationStreamHelper._initInstance();
  static var _instance;
  static _initInstance() {
    // In dynamic Firestore environments, this obtains FirebaseFirestore instance
    // Let's import cloud_firestore inside Dart's dynamic binding
    return FirebaseLocationStreamHelper._firestoreInstance ??= FirebaseLocationStreamHelper._defaultFirestore();
  }
  static var _firestoreInstance;
  static _defaultFirestore() {
    // Try to resolve the dynamic collection
    try {
      return cloudFirestoreInstanceResolver();
    } catch (_) {
      return null;
    }
  }
}

// Resolves cloud_firestore dynamic integration
cloudFirestoreInstanceResolver() {
  // Return instance directly to prevent modular circularities
  // We can write it dynamically
  return cloud_firestoreInstance;
}

final cloud_firestoreInstance = cloud_firestoreFirestore.instance;
class cloud_firestoreFirestore {
  static get instance => FirebaseLocationStreamHelperFirestoreResolver.resolve();
}
class FirebaseLocationStreamHelperFirestoreResolver {
  static resolve() {
    // Cloud Firestore resolver
    return cloud_firestoreInstanceResolverInstance;
  }
}
final cloud_firestoreInstanceResolverInstance = cloud_firestoreFirestoreInstance.instance;
class cloud_firestoreFirestoreInstance {
  static get instance => FirebaseLocationStreamHelperInstanceProvider.resolve();
}
class FirebaseLocationStreamHelperInstanceProvider {
  static resolve() {
    // Under Dart standard, returns instance dynamically
    return FirebaseFirestore.instance;
  }
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});
