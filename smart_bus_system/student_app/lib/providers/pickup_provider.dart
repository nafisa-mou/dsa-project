import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/services/pickup_coordination_service.dart';
import '../../backend/firebase/firebase_models.dart';
import 'auth_provider.dart';
import 'dart:async';

class PickupState {
  final PickupRequestModel? activeRequest;
  final List<PickupRequestModel> requestHistory;
  final bool isLoading;
  final String? errorMessage;

  PickupState({
    this.activeRequest,
    this.requestHistory = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PickupState copyWith({
    PickupRequestModel? activeRequest,
    List<PickupRequestModel>? requestHistory,
    bool? isLoading,
    String? errorMessage,
    bool clearActiveRequest = false,
    bool clearError = false,
  }) {
    return PickupState(
      activeRequest: clearActiveRequest ? null : (activeRequest ?? this.activeRequest),
      requestHistory: requestHistory ?? this.requestHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PickupNotifier extends StateNotifier<PickupState> {
  final PickupCoordinationService _pickupService = PickupCoordinationService();
  StreamSubscription? _requestsSubscription;
  final Ref _ref;

  PickupNotifier(this._ref) : super(PickupState()) {
    _initRequestsListener();
  }

  void _initRequestsListener() {
    // Listen to changes in Auth state to subscribe to student-specific requests
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null) {
        _subscribeToStudentRequests(next.user!.id);
      } else {
        _unsubscribe();
      }
    });

    // Handle initial subscription if user is already logged in
    final authState = _ref.read(authProvider);
    if (authState.user != null) {
      _subscribeToStudentRequests(authState.user!.id);
    }
  }

  void _subscribeToStudentRequests(String studentId) {
    _requestsSubscription?.cancel();
    _requestsSubscription = _pickupService.streamStudentPickupRequests(studentId)
        .listen((requests) {
          if (requests.isEmpty) {
            state = state.copyWith(requestHistory: [], clearActiveRequest: true);
            return;
          }

          // Check if there is an active request (pending or accepted)
          final active = requests.firstWhere(
            (r) => r.status == 'pending' || r.status == 'accepted',
            orElse: () => requests.first, // fallback if none are active
          );

          final hasActive = active.status == 'pending' || active.status == 'accepted';

          state = state.copyWith(
            activeRequest: hasActive ? active : null,
            requestHistory: requests,
            clearActiveRequest: !hasActive,
          );
        }, onError: (e) {
          state = state.copyWith(errorMessage: 'Failed to stream pickup requests: $e');
        });
  }

  void _unsubscribe() {
    _requestsSubscription?.cancel();
    state = PickupState();
  }

  Future<bool> createRequest({
    required double latitude,
    required double longitude,
    required PickupPriority priority,
    DateTime? desiredArrivalTime,
  }) async {
    final authState = _ref.read(authProvider);
    if (authState.user == null) {
      state = state.copyWith(errorMessage: 'User must be logged in to request a pickup');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _pickupService.createPickupRequest(
        studentId: authState.user!.id,
        studentName: authState.user!.name,
        studentPhone: '01700000000', // Retrieve from profile in production
        pickupLatitude: latitude,
        pickupLongitude: longitude,
        priority: priority,
        desiredArrivalTime: desiredArrivalTime,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to create pickup: $e');
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _pickupService.cancelPickupRequest(requestId);
      state = state.copyWith(isLoading: false, clearActiveRequest: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to cancel request: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }
}

final pickupProvider = StateNotifierProvider<PickupNotifier, PickupState>((ref) {
  return PickupNotifier(ref);
});
