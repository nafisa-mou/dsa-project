import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/firebase/firebase_models.dart';
import '../../backend/services/location_service.dart';
import '../../backend/services/pickup_coordination_service.dart';
import 'auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class RouteState {
  final Trip? activeTrip;
  final List<PickupRequestModel> assignedPickups;
  final bool isDriving;
  final double currentLatitude;
  final double currentLongitude;
  final String? errorMessage;
  final bool isLoading;

  RouteState({
    this.activeTrip,
    this.assignedPickups = const [],
    this.isDriving = false,
    this.currentLatitude = 23.8103,
    this.currentLongitude = 90.4125,
    this.errorMessage,
    this.isLoading = false,
  });

  RouteState copyWith({
    Trip? activeTrip,
    List<PickupRequestModel>? assignedPickups,
    bool? isDriving,
    double? currentLatitude,
    double? currentLongitude,
    String? errorMessage,
    bool? isLoading,
    bool clearActiveTrip = false,
    bool clearError = false,
  }) {
    return RouteState(
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      assignedPickups: assignedPickups ?? this.assignedPickups,
      isDriving: isDriving ?? this.isDriving,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RouteNotifier extends StateNotifier<RouteState> {
  final LocationService _locationService = LocationService();
  final PickupCoordinationService _pickupService = PickupCoordinationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;
  StreamSubscription? _pickupsSubscription;
  Timer? _gpsSimulationTimer;

  RouteNotifier(this._ref) : super(RouteState()) {
    _initListeners();
  }

  void _initListeners() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null) {
        _subscribeToAssignedPickups(next.user!.id);
      } else {
        _unsubscribe();
      }
    });

    final auth = _ref.read(authProvider);
    if (auth.user != null) {
      _subscribeToAssignedPickups(auth.user!.id);
    }
  }

  void _subscribeToAssignedPickups(String driverId) {
    _pickupsSubscription?.cancel();
    _pickupsSubscription = _firestore
        .collection('pickup_requests')
        .where('assignedDriverId', isEqualTo: driverId)
        .where('status', whereIn: ['accepted', 'pending'])
        .snapshots()
        .map((snap) => snap.docs.map((doc) => PickupRequestModel.fromMap(doc.data())).toList())
        .listen((pickups) {
          state = state.copyWith(assignedPickups: pickups);
        }, onError: (e) {
          state = state.copyWith(errorMessage: 'Failed to stream pickups: $e');
        });
  }

  void _unsubscribe() {
    _pickupsSubscription?.cancel();
    _gpsSimulationTimer?.cancel();
    state = RouteState();
  }

  Future<bool> startTrip(String routeName, List<String> stops) async {
    final auth = _ref.read(authProvider);
    if (auth.user == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final tripId = const Uuid().v4();
      final newTrip = Trip(
        id: tripId,
        busId: 'bus_${auth.user!.id.substring(0, 5)}',
        driverId: auth.user!.id,
        routeName: routeName,
        startTime: DateTime.now(),
        stopsSequence: stops,
        status: 'in_progress',
      );

      await _firestore.collection('trips').doc(tripId).set(newTrip.toMap());
      await _firestore.collection('drivers').doc(auth.user!.id).update({'status': 'on_duty'});

      state = state.copyWith(
        activeTrip: newTrip,
        isDriving: true,
        isLoading: false,
      );

      _startGpsSimulation();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Start Trip failed: $e');
      return false;
    }
  }

  void _startGpsSimulation() {
    _gpsSimulationTimer?.cancel();
    double step = 0.001; // Mock stepping GPS
    _gpsSimulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (state.activeTrip == null) {
        timer.cancel();
        return;
      }

      final newLat = state.currentLatitude + step;
      final newLng = state.currentLongitude + (step * 0.5);

      state = state.copyWith(currentLatitude: newLat, currentLongitude: newLng);

      // Stream updates to Firebase live_locations
      await _locationService.updateBusLocation(
        state.activeTrip!.busId,
        newLat,
        newLng,
        speed: 35.0,
        heading: 45.0,
      );
    });
  }

  Future<void> endTrip() async {
    if (state.activeTrip == null) return;

    state = state.copyWith(isLoading: true);
    _gpsSimulationTimer?.cancel();

    try {
      final auth = _ref.read(authProvider);
      final tripId = state.activeTrip!.id;

      await _firestore.collection('trips').doc(tripId).update({
        'status': 'completed',
        'endTime': DateTime.now().toIso8601String(),
      });

      if (auth.user != null) {
        await _firestore.collection('drivers').doc(auth.user!.id).update({'status': 'available'});
      }

      state = state.copyWith(
        clearActiveTrip: true,
        isDriving: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to end trip: $e');
    }
  }

  Future<void> boardStudent(String studentId) async {
    if (state.activeTrip == null) return;
    
    final updatedStudents = List<String>.from(state.activeTrip!.studentsBoarded)..add(studentId);
    final updatedTrip = Trip(
      id: state.activeTrip!.id,
      busId: state.activeTrip!.busId,
      driverId: state.activeTrip!.driverId,
      routeName: state.activeTrip!.routeName,
      startTime: state.activeTrip!.startTime,
      stopsSequence: state.activeTrip!.stopsSequence,
      studentsBoarded: updatedStudents,
      status: state.activeTrip!.status,
    );

    try {
      await _firestore.collection('trips').doc(state.activeTrip!.id).update({
        'studentsBoarded': FieldValue.arrayUnion([studentId]),
      });
      state = state.copyWith(activeTrip: updatedTrip);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Boarding failed: $e');
    }
  }

  Future<void> completePickup(String requestId, String studentId) async {
    if (state.activeTrip == null) return;

    try {
      await _pickupService.completePickupRequest(requestId, studentId, state.activeTrip!.busId);
      await boardStudent(studentId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to complete pickup: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _pickupsSubscription?.cancel();
    _gpsSimulationTimer?.cancel();
    super.dispose();
  }
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  return RouteNotifier(ref);
});
