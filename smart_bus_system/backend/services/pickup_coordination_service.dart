/// Pickup Coordination Service
/// 
/// Responsibilities:
/// - Create and manage pickup requests
/// - Assign buses to pickup requests
/// - Optimize pickup sequence
/// - Handle pickup completion/cancellation

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../dsa_algorithms/priority_queue_scheduler.dart';
import '../dsa_algorithms/dijkstra_algorithm.dart';
import '../dsa_algorithms/hash_maps.dart';
import '../firebase/firebase_models.dart';

class PickupCoordinationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PickupScheduler _scheduler = PickupScheduler();
  final EntityHashMap _entityMap = EntityHashMap();
  final DijkstraAlgorithm? _dijkstra;

  PickupCoordinationService({DijkstraAlgorithm? dijkstra})
      : _dijkstra = dijkstra;

  /// Create a new pickup request
  Future<PickupRequestModel> createPickupRequest({
    required String studentId,
    required String studentName,
    required String studentPhone,
    required double pickupLatitude,
    required double pickupLongitude,
    PickupPriority priority = PickupPriority.medium,
    DateTime? desiredArrivalTime,
  }) async {
    try {
      final requestId = const Uuid().v4();
      final now = DateTime.now();

      final request = PickupRequestModel(
        id: requestId,
        studentId: studentId,
        studentName: studentName,
        studentPhone: studentPhone,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        requestTime: now,
        status: 'pending',
      );

      // Save to Firestore
      await _firestore
          .collection('pickup_requests')
          .doc(requestId)
          .set(request.toMap());

      // Add to priority queue
      final priorityRequest = PickupRequest(
        id: requestId,
        studentId: studentId,
        studentName: studentName,
        latitude: pickupLatitude,
        longitude: pickupLongitude,
        department: '',
        priority: priority,
        requestTime: now,
        desiredArrivalTime: desiredArrivalTime,
        isUrgent: priority == PickupPriority.critical,
      );

      _scheduler.addPickupRequest(priorityRequest);

      return request;
    } catch (e) {
      print('Error creating pickup request: $e');
      rethrow;
    }
  }

  /// Get next pickup to assign
  PickupRequest? getNextPickupToAssign() {
    return _scheduler.getNextPickup();
  }

  /// Assign bus to pickup request
  Future<void> assignBusToPickup(
    String requestId,
    String busId,
    String driverId,
    double estimatedArrivalMinutes,
  ) async {
    try {
      await _firestore
          .collection('pickup_requests')
          .doc(requestId)
          .update({
            'assignedBusId': busId,
            'assignedDriverId': driverId,
            'estimatedArrivalMinutes': estimatedArrivalMinutes,
            'status': 'accepted',
          });
    } catch (e) {
      print('Error assigning bus to pickup: $e');
      rethrow;
    }
  }

  /// Complete a pickup request
  Future<void> completePickupRequest(
    String requestId,
    String studentId,
    String busId,
  ) async {
    try {
      await _firestore
          .collection('pickup_requests')
          .doc(requestId)
          .update({
            'status': 'completed',
            'completedTime': DateTime.now().toIso8601String(),
          });

      // Remove from scheduler
      _scheduler.removePickupRequest(requestId);

      // Update trip document
      final trip = await _firestore
          .collection('trips')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'in_progress')
          .limit(1)
          .get();

      if (trip.docs.isNotEmpty) {
        await trip.docs.first.reference.update({
          'studentsBoarded': FieldValue.arrayUnion([studentId]),
        });
      }
    } catch (e) {
      print('Error completing pickup request: $e');
      rethrow;
    }
  }

  /// Cancel a pickup request
  Future<void> cancelPickupRequest(String requestId) async {
    try {
      await _firestore
          .collection('pickup_requests')
          .doc(requestId)
          .update({
            'status': 'cancelled',
            'completedTime': DateTime.now().toIso8601String(),
          });

      _scheduler.removePickupRequest(requestId);
    } catch (e) {
      print('Error cancelling pickup request: $e');
      rethrow;
    }
  }

  /// Get all pending pickup requests
  Future<List<PickupRequestModel>> getPendingPickupRequests() async {
    try {
      final snapshot = await _firestore
          .collection('pickup_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => PickupRequestModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching pending requests: $e');
      return [];
    }
  }

  /// Stream pickup requests for a student
  Stream<List<PickupRequestModel>> streamStudentPickupRequests(
      String studentId) {
    return _firestore
        .collection('pickup_requests')
        .where('studentId', isEqualTo: studentId)
        .orderBy('requestTime', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PickupRequestModel.fromMap(doc.data()))
            .toList());
  }

  /// Get pending request count
  Future<int> getPendingRequestCount() async {
    try {
      final snapshot = await _firestore
          .collection('pickup_requests')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting pending request count: $e');
      return 0;
    }
  }

  /// Update bus distance in scheduler
  void updateBusLocationForScheduler(
    double busLatitude,
    double busLongitude,
  ) {
    _scheduler.updateBusDistance(busLatitude, busLongitude);
  }

  /// Get top N priority pickups
  List<PickupRequest> getTopPriorityPickups(int count) {
    return _scheduler.getTopRequests(count);
  }

  /// Get all pending requests with current priorities
  List<PickupRequest> getAllPendingWithPriorities() {
    return _scheduler.getAllPendingRequests();
  }

  /// Expire old pending requests (timeout after 15 minutes)
  Future<void> expireOldPickupRequests() async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(minutes: 15));

      await _firestore
          .collection('pickup_requests')
          .where('status', isEqualTo: 'pending')
          .where('requestTime', isLessThan: cutoffTime.toIso8601String())
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.update({'status': 'expired'});
              _scheduler.removePickupRequest(doc.id);
            }
          });
    } catch (e) {
      print('Error expiring old requests: $e');
    }
  }
}
