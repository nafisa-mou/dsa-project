/// Route Optimization Service
/// 
/// Responsibilities:
/// - Calculate optimal bus routes
/// - Manage bus stops and road networks
/// - Optimize pickup sequences
/// - Calculate ETAs

import 'package:cloud_firestore/cloud_firestore.dart';
import '../dsa_algorithms/graph_model.dart';
import '../dsa_algorithms/dijkstra_algorithm.dart';
import '../dsa_algorithms/graph_traversal.dart';

class RouteOptimizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late BusNetworkGraph _busNetwork;
  late DijkstraAlgorithm _dijkstra;
  late GraphTraversal _traversal;

  RouteOptimizationService() {
    _busNetwork = BusNetworkGraph();
    _dijkstra = DijkstraAlgorithm(_busNetwork);
    _traversal = GraphTraversal(_busNetwork);
  }

  /// Initialize bus network from Firestore
  Future<void> initializeBusNetwork() async {
    try {
      // Fetch all bus stops
      final stopsSnapshot = await _firestore
          .collection('bus_stops')
          .get();

      for (var stopDoc in stopsSnapshot.docs) {
        final data = stopDoc.data();
        final stop = BusStop(
          id: stopDoc.id,
          name: data['name'] ?? '',
          location: LatLng(
            data['latitude'] ?? 0.0,
            data['longitude'] ?? 0.0,
          ),
          description: data['description'],
        );
        _busNetwork.addStop(stop);
      }

      // Fetch all road connections
      final routesSnapshot = await _firestore
          .collection('road_network')
          .get();

      for (var routeDoc in routesSnapshot.docs) {
        final data = routeDoc.data();
        final edge = RoadEdge(
          fromStopId: data['fromStopId'] ?? '',
          toStopId: data['toStopId'] ?? '',
          distance: data['distance']?.toDouble() ?? 0.0,
          estimatedTime: data['estimatedTime']?.toDouble() ?? 0.0,
          isBidirectional: data['isBidirectional'] ?? true,
        );
        _busNetwork.addRoad(edge);
      }

      print('Bus network initialized: ${_busNetwork.getStopCount()} stops, '
          '${_busNetwork.getEdgeCount()} edges');
    } catch (e) {
      print('Error initializing bus network: $e');
      rethrow;
    }
  }

  /// Find shortest route between two stops
  Future<DijkstraResult> calculateShortestRoute(
    String fromStopId,
    String toStopId, {
    bool optimizeForTime = true,
  }) async {
    try {
      final result = _dijkstra.findShortestPath(
        fromStopId,
        toStopId,
        useTime: optimizeForTime,
      );

      return result;
    } catch (e) {
      print('Error calculating shortest route: $e');
      rethrow;
    }
  }

  /// Find optimal pickup sequence for a bus
  Future<List<String>> optimizePickupSequence(
    String busCurrentStopId,
    List<String> pendingPickupStopIds,
  ) async {
    try {
      if (pendingPickupStopIds.isEmpty) return [];

      // Convert student locations to nearest stops
      final sequence = _dijkstra.optimizePickupSequence(
        busCurrentStopId,
        pendingPickupStopIds,
      );

      return sequence;
    } catch (e) {
      print('Error optimizing pickup sequence: $e');
      rethrow;
    }
  }

  /// Calculate ETA for bus to reach a stop
  Future<double> calculateETAToStop(
    String busCurrentStopId,
    String destinationStopId,
  ) async {
    try {
      final result = _dijkstra.findShortestPath(
        busCurrentStopId,
        destinationStopId,
        useTime: true,
      );

      return result.totalTime;
    } catch (e) {
      print('Error calculating ETA: $e');
      return 0;
    }
  }

  /// Get all stops reachable from a given stop
  List<BusStop> getReachableStops(String fromStopId) {
    final reachableIds = _traversal.getReachableStops(fromStopId);
    final stops = <BusStop>[];

    for (var stopId in reachableIds) {
      final stop = _busNetwork.getStop(stopId);
      if (stop != null) {
        stops.add(stop);
      }
    }

    return stops;
  }

  /// Check if bus network is fully connected
  bool isNetworkConnected() {
    return _traversal.isConnected();
  }

  /// Get connected components (groups of stops)
  List<List<BusStop>> getConnectedComponents() {
    final components = _traversal.findConnectedComponents();
    final stopComponents = <List<BusStop>>[];

    for (var component in components) {
      final stops = component
          .map((id) => _busNetwork.getStop(id))
          .whereType<BusStop>()
          .toList();
      stopComponents.add(stops);
    }

    return stopComponents;
  }

  /// Calculate optimal route for multiple stops
  Future<List<String>> calculateOptimalRoute(
    String startStopId,
    List<String> stopIds,
  ) async {
    try {
      // Use nearest neighbor greedy approach
      final route = <String>[startStopId];
      final remaining = Set<String>.from(stopIds);

      while (remaining.isNotEmpty) {
        final last = route.last;
        var nearest = remaining.first;
        var minTime = double.infinity;

        for (var stopId in remaining) {
          final result = _dijkstra.findShortestPath(last, stopId, useTime: true);
          if (result.totalTime < minTime) {
            minTime = result.totalTime;
            nearest = stopId;
          }
        }

        route.add(nearest);
        remaining.remove(nearest);
      }

      return route;
    } catch (e) {
      print('Error calculating optimal route: $e');
      rethrow;
    }
  }

  /// Get nearest stops to a location
  List<BusStop> getNearestStops(
    double latitude,
    double longitude, {
    required int count,
  }) {
    final location = LatLng(latitude, longitude);
    return _dijkstra.findNearestStops(location, k: count);
  }

  /// Get graph statistics
  Map<String, dynamic> getNetworkStats() {
    return {
      'totalStops': _busNetwork.getStopCount(),
      'totalRoads': _busNetwork.getEdgeCount(),
      'isConnected': isNetworkConnected(),
      'components': getConnectedComponents().length,
    };
  }
}
