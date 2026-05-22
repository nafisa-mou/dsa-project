/// DSA: Graph Model for Bus Stop Network and Road Network
/// 
/// This implements a directed weighted graph where:
/// - Nodes represent bus stops/locations
/// - Edges represent roads with distances/travel times
/// - Weights represent distances or travel time estimates

import 'package:collection/collection.dart';
import 'dart:math' as math;

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  /// Haversine formula for distance between two coordinates
  double distanceTo(LatLng other) {
    const double earthRadiusKm = 6371;

    double dLat = _toRadians(other.latitude - latitude);
    double dLon = _toRadians(other.longitude - longitude);

    double a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * (3.14159265359 / 180);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

class BusStop {
  final String id;
  final String name;
  final LatLng location;
  final String? description;
  final DateTime createdAt;

  BusStop({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusStop &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Edge in the graph representing a road/route between two stops
class RoadEdge {
  final String fromStopId;
  final String toStopId;
  final double distance; // in kilometers
  final double estimatedTime; // in minutes
  final bool isBidirectional;

  RoadEdge({
    required this.fromStopId,
    required this.toStopId,
    required this.distance,
    required this.estimatedTime,
    this.isBidirectional = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoadEdge &&
          runtimeType == other.runtimeType &&
          fromStopId == other.fromStopId &&
          toStopId == other.toStopId;

  @override
  int get hashCode => fromStopId.hashCode ^ toStopId.hashCode;
}

/// Complete Graph implementation for bus network
class BusNetworkGraph {
  // Adjacency list: stopId -> List of edges from that stop
  final Map<String, List<RoadEdge>> adjacencyList = {};
  
  // Store all stops for quick lookup
  final Map<String, BusStop> stops = {};

  /// Add a bus stop to the graph
  void addStop(BusStop stop) {
    stops[stop.id] = stop;
    adjacencyList.putIfAbsent(stop.id, () => []);
  }

  /// Add a road connection between two stops
  void addRoad(RoadEdge edge) {
    adjacencyList.putIfAbsent(edge.fromStopId, () => []);
    adjacencyList.putIfAbsent(edge.toStopId, () => []);

    // Check for duplicate
    if (!adjacencyList[edge.fromStopId]!.any(
        (e) => e.toStopId == edge.toStopId)) {
      adjacencyList[edge.fromStopId]!.add(edge);
    }

    // If bidirectional, add reverse edge
    if (edge.isBidirectional) {
      var reverseEdge = RoadEdge(
        fromStopId: edge.toStopId,
        toStopId: edge.fromStopId,
        distance: edge.distance,
        estimatedTime: edge.estimatedTime,
        isBidirectional: false,
      );

      if (!adjacencyList[edge.toStopId]!.any(
          (e) => e.toStopId == edge.fromStopId)) {
        adjacencyList[edge.toStopId]!.add(reverseEdge);
      }
    }
  }

  /// Get all neighbors of a stop
  List<BusStop>? getNeighbors(String stopId) {
    var edges = adjacencyList[stopId];
    if (edges == null) return null;
    return edges.map((e) => stops[e.toStopId]).whereType<BusStop>().toList();
  }

  /// Get edges from a stop
  List<RoadEdge>? getEdgesFrom(String stopId) => adjacencyList[stopId];

  /// Get stop by ID
  BusStop? getStop(String stopId) => stops[stopId];

  /// Get all stops
  List<BusStop> getAllStops() => stops.values.toList();

  /// Check if stops are connected
  bool hasEdge(String fromId, String toId) {
    return adjacencyList[fromId]?.any((e) => e.toStopId == toId) ?? false;
  }

  /// Graph statistics
  int getStopCount() => stops.length;
  
  int getEdgeCount() => 
      adjacencyList.values.fold(0, (sum, edges) => sum + edges.length);
}
