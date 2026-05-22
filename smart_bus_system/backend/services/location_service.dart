/// Location Service for GPS tracking and management
/// 
/// Responsibilities:
/// - Track real-time GPS locations
/// - Manage live location streaming
/// - Handle location privacy
/// - Calculate distances and ETAs

import 'package:cloud_firestore/cloud_firestore.dart';
import '../dsa_algorithms/dijkstra_algorithm.dart';
import '../dsa_algorithms/graph_model.dart';
import '../firebase/firebase_models.dart';
import 'dart:async';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription? _busLocationSubscription;
  StreamSubscription? _studentLocationSubscription;
  
  final Map<String, LiveLocation> _cachedLocations = {};

  /// Start tracking bus location updates
  Stream<LiveLocation> trackBusLocation(String busId) {
    return _firestore
        .collection('live_locations')
        .where('entityId', isEqualTo: busId)
        .where('entityType', isEqualTo: 'bus')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final location = LiveLocation.fromMap(
              snapshot.docs.first.data(),
            );
            _cachedLocations[busId] = location;
            return location;
          }
          throw Exception('Location not found');
        });
  }

  /// Update bus location in real-time database
  Future<void> updateBusLocation(
    String busId,
    double latitude,
    double longitude, {
    double? speed,
    double? heading,
  }) async {
    final location = LiveLocation(
      entityId: busId,
      entityType: 'bus',
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      speed: speed,
      heading: heading,
    );

    try {
      // Update in Firestore
      await _firestore
          .collection('live_locations')
          .doc(busId)
          .set(location.toMap(), SetOptions(merge: true));

      // Cache locally
      _cachedLocations[busId] = location;
    } catch (e) {
      print('Error updating bus location: $e');
      rethrow;
    }
  }

  /// Update student location (only when sharing)
  Future<void> updateStudentLocation(
    String studentId,
    double latitude,
    double longitude,
  ) async {
    final location = LiveLocation(
      entityId: studentId,
      entityType: 'student',
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );

    try {
      await _firestore
          .collection('live_locations')
          .doc(studentId)
          .set(location.toMap(), SetOptions(merge: true));

      _cachedLocations[studentId] = location;
    } catch (e) {
      print('Error updating student location: $e');
      rethrow;
    }
  }

  /// Stop sharing student location
  Future<void> stopLocationSharing(String studentId) async {
    try {
      await _firestore
          .collection('live_locations')
          .doc(studentId)
          .update({'isActive': false});

      _cachedLocations.remove(studentId);
    } catch (e) {
      print('Error stopping location sharing: $e');
    }
  }

  /// Get cached location (O(1) lookup)
  LiveLocation? getCachedLocation(String entityId) {
    return _cachedLocations[entityId];
  }

  /// Fetch location from Firestore
  Future<LiveLocation?> getLocation(String entityId) async {
    try {
      final doc = await _firestore
          .collection('live_locations')
          .doc(entityId)
          .get();

      if (doc.exists) {
        final location = LiveLocation.fromMap(doc.data() ?? {});
        _cachedLocations[entityId] = location;
        return location;
      }
      return null;
    } catch (e) {
      print('Error fetching location: $e');
      return null;
    }
  }

  /// Calculate distance between two locations
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return LatLng(lat1, lon1).distanceTo(LatLng(lat2, lon2));
  }

  /// Calculate ETA from current location to destination
  Future<double> calculateETA(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) async {
    // Simple calculation: average speed 20 km/h in city
    final distance = calculateDistance(fromLat, fromLon, toLat, toLon);
    final estimatedMinutes = (distance / 20) * 60;
    return estimatedMinutes;
  }

  /// Clean up old location data
  Future<void> cleanupOldLocations(int olderThanMinutes) async {
    try {
      final cutoffTime = DateTime.now()
          .subtract(Duration(minutes: olderThanMinutes));

      await _firestore
          .collection('live_locations')
          .where('timestamp', isLessThan: cutoffTime.toIso8601String())
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
    } catch (e) {
      print('Error cleaning up locations: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _busLocationSubscription?.cancel();
    _studentLocationSubscription?.cancel();
    _cachedLocations.clear();
  }
}
