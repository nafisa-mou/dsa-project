/// DSA: Priority Queue for Pickup Request Scheduling
/// 
/// Used for:
/// - Prioritizing pickup requests (urgent, distance, time)
/// - Managing driver assignment queue
/// - Scheduling bus stops in optimal order

import 'package:collection/collection.dart';
import 'dart:math' as Math;

enum PickupPriority {
  critical, // Emergency, disabled, VIP
  high,     // Within 2 min of missed class
  medium,   // Regular pickup
  low,      // Flexible timing
}

class PickupRequest {
  final String id;
  final String studentId;
  final String studentName;
  final double latitude;
  final double longitude;
  final String department;
  final PickupPriority priority;
  final DateTime requestTime;
  final DateTime? desiredArrivalTime;
  final bool isUrgent;
  double distanceFromBus; // Will be calculated and updated

  PickupRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.latitude,
    required this.longitude,
    required this.department,
    required this.priority,
    required this.requestTime,
    this.desiredArrivalTime,
    required this.isUrgent,
    this.distanceFromBus = double.infinity,
  });

  /// Calculate priority score (higher = more urgent)
  double calculatePriorityScore(DateTime currentTime) {
    double baseScore = 0;

    // Priority level score
    switch (priority) {
      case PickupPriority.critical:
        baseScore = 1000;
        break;
      case PickupPriority.high:
        baseScore = 700;
        break;
      case PickupPriority.medium:
        baseScore = 400;
        break;
      case PickupPriority.low:
        baseScore = 100;
        break;
    }

    // Time factor - older requests get higher priority
    final secondsWaited =
        currentTime.difference(requestTime).inSeconds;
    baseScore += secondsWaited / 60; // +1 score per minute waited

    // Distance factor - closer students are prioritized (if within reasonable distance)
    if (distanceFromBus < 5) {
      baseScore += (5 - distanceFromBus) * 50;
    } else {
      baseScore -= (distanceFromBus - 5) * 10;
    }

    // Desired arrival time factor
    if (desiredArrivalTime != null) {
      final timeUntilDesired =
          desiredArrivalTime!.difference(currentTime).inMinutes;
      if (timeUntilDesired < 10 && timeUntilDesired > 0) {
        baseScore += (10 - timeUntilDesired) * 50;
      }
    }

    return baseScore;
  }
}

class PickupScheduler {
  final PriorityQueue<PickupRequest> _queue = PriorityQueue<PickupRequest>(
    (a, b) => b.calculatePriorityScore(DateTime.now())
        .compareTo(a.calculatePriorityScore(DateTime.now())),
  );

  final Map<String, PickupRequest> _requestMap = {};

  /// Add a pickup request to the queue
  void addPickupRequest(PickupRequest request) {
    if (_requestMap.containsKey(request.id)) {
      // Remove old request
      _queue.removeAll([_requestMap[request.id]!]);
    }

    _requestMap[request.id] = request;
    _queue.add(request);
  }

  /// Remove a pickup request from the queue
  bool removePickupRequest(String requestId) {
    if (!_requestMap.containsKey(requestId)) return false;

    final request = _requestMap[requestId]!;
    _queue.removeAll([request]);
    _requestMap.remove(requestId);
    return true;
  }

  /// Get next pickup to handle
  PickupRequest? getNextPickup() {
    while (_queue.isNotEmpty) {
      final request = _queue.removeFirst();
      if (_requestMap.containsKey(request.id)) {
        return request;
      }
    }
    return null;
  }

  /// Peek at next pickup without removing
  PickupRequest? peekNextPickup() {
    while (_queue.isNotEmpty) {
      final request = _queue.first;
      if (_requestMap.containsKey(request.id)) {
        return request;
      }
      _queue.removeFirst();
    }
    return null;
  }

  /// Get all pending requests (rebuilt in priority order)
  List<PickupRequest> getAllPendingRequests() {
    final all = _requestMap.values.toList();
    all.sort((a, b) => b
        .calculatePriorityScore(DateTime.now())
        .compareTo(a.calculatePriorityScore(DateTime.now())));
    return all;
  }

  /// Update distance for all requests (when bus moves)
  void updateBusDistance(double busLatitude, double busLongitude) {
    for (var request in _requestMap.values) {
      request.distanceFromBus = _calculateDistance(
        busLatitude,
        busLongitude,
        request.latitude,
        request.longitude,
      );
    }

    // Rebuild priority queue as distances changed
    _rebuildQueue();
  }

  /// Clear all requests
  void clearAll() {
    _queue.clear();
    _requestMap.clear();
  }

  /// Get request by ID
  PickupRequest? getRequestById(String requestId) =>
      _requestMap[requestId];

  /// Get number of pending requests
  int getPendingCount() => _requestMap.length;

  /// Get top N requests
  List<PickupRequest> getTopRequests(int count) {
    final all = getAllPendingRequests();
    return all.take(count).toList();
  }

  void _rebuildQueue() {
    // Clear and rebuild queue with new priorities
    final requests = _requestMap.values.toList();
    _queue.clear();
    for (var request in requests) {
      _queue.add(request);
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371;

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_toRadians(lat1)) *
            Math.cos(_toRadians(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2));

    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * (3.14159265359 / 180);
}
