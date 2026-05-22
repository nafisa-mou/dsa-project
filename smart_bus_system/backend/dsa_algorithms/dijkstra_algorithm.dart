/// DSA: Dijkstra Algorithm for Shortest Path and ETA Calculation
/// 
/// Used for:
/// - Finding shortest route between bus stops
/// - Calculating ETA (Estimated Time of Arrival)
/// - Optimizing pickup sequencing
/// - Route planning

import 'package:collection/collection.dart';
import 'graph_model.dart';

class DijkstraResult {
  final String? destinationStopId;
  final double totalDistance; // in km
  final double totalTime; // in minutes
  final List<String> routePath; // ordered list of stop IDs
  final Map<String, double> distances;
  final Map<String, double> times;

  DijkstraResult({
    required this.destinationStopId,
    required this.totalDistance,
    required this.totalTime,
    required this.routePath,
    required this.distances,
    required this.times,
  });

  /// ETA calculation with current time
  DateTime calculateETA(DateTime departureTime) {
    return departureTime.add(Duration(minutes: totalTime.toInt()));
  }

  /// Get route details in readable format
  String getRouteDescription(BusNetworkGraph graph) {
    return routePath
        .map((id) => graph.getStop(id)?.name ?? id)
        .join(' → ');
  }
}

class DijkstraAlgorithm {
  final BusNetworkGraph graph;

  DijkstraAlgorithm(this.graph);

  /// Find shortest path from source to destination
  /// Uses Dijkstra's algorithm
  DijkstraResult findShortestPath(
    String sourceStopId,
    String destinationStopId, {
    bool useTime = false, // If true, optimize for time; else optimize for distance
  }) {
    // Initialize distances and times
    final distances = <String, double>{};
    final times = <String, double>{};
    final previous = <String, String?>{};
    final visited = <String>{};
    final priorityQueue = PriorityQueue<_DijkstraNode>(
        (a, b) => a.cost.compareTo(b.cost));

    // Initialize all distances to infinity
    for (var stop in graph.getAllStops()) {
      distances[stop.id] = double.infinity;
      times[stop.id] = double.infinity;
      previous[stop.id] = null;
    }

    // Source distance is 0
    distances[sourceStopId] = 0;
    times[sourceStopId] = 0;

    // Add source to priority queue
    priorityQueue.add(_DijkstraNode(
      stopId: sourceStopId,
      cost: 0,
    ));

    // Dijkstra's algorithm
    while (priorityQueue.isNotEmpty) {
      final current = priorityQueue.removeFirst();

      if (visited.contains(current.stopId)) continue;
      visited.add(current.stopId);

      // If we reached destination, we can stop
      if (current.stopId == destinationStopId) break;

      // Check all neighbors
      final edges = graph.getEdgesFrom(current.stopId);
      if (edges != null) {
        for (var edge in edges) {
          if (visited.contains(edge.toStopId)) continue;

          // Calculate new cost (distance or time)
          final newDistance = (distances[current.stopId] ?? 0) + edge.distance;
          final newTime = (times[current.stopId] ?? 0) + edge.estimatedTime;
          final newCost = useTime ? newTime : newDistance;
          final currentCost = useTime
              ? (times[edge.toStopId] ?? double.infinity)
              : (distances[edge.toStopId] ?? double.infinity);

          // If we found a shorter path, update it
          if (newCost < currentCost) {
            distances[edge.toStopId] = newDistance;
            times[edge.toStopId] = newTime;
            previous[edge.toStopId] = current.stopId;

            priorityQueue.add(_DijkstraNode(
              stopId: edge.toStopId,
              cost: newCost,
            ));
          }
        }
      }
    }

    // Reconstruct path
    final path = _reconstructPath(previous, sourceStopId, destinationStopId);

    return DijkstraResult(
      destinationStopId: destinationStopId,
      totalDistance: distances[destinationStopId] ?? double.infinity,
      totalTime: times[destinationStopId] ?? double.infinity,
      routePath: path,
      distances: distances,
      times: times,
    );
  }

  /// Find shortest paths from source to all other stops
  Map<String, DijkstraResult> findAllShortestPaths(
    String sourceStopId, {
    bool useTime = false,
  }) {
    final results = <String, DijkstraResult>{};

    for (var stop in graph.getAllStops()) {
      if (stop.id != sourceStopId) {
        results[stop.id] = findShortestPath(
          sourceStopId,
          stop.id,
          useTime: useTime,
        );
      }
    }

    return results;
  }

  /// Find K nearest stops to a given location
  List<BusStop> findNearestStops(
    LatLng location, {
    required int k,
  }) {
    final stopsWithDistance = graph.getAllStops().map((stop) {
      return MapEntry(
        stop,
        location.distanceTo(stop.location),
      );
    }).toList();

    stopsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    return stopsWithDistance.take(k).map((e) => e.key).toList();
  }

  /// Calculate optimal pickup sequence from current bus position
  /// Returns stops sorted by optimal pickup order
  List<String> optimizePickupSequence(
    String busCurrentStopId,
    List<String> pendingPickupStopIds,
  ) {
    if (pendingPickupStopIds.isEmpty) return [];
    if (pendingPickupStopIds.length == 1) return pendingPickupStopIds;

    // Use greedy nearest-neighbor for quick optimization
    final sequence = <String>[];
    var currentStop = busCurrentStopId;
    final remaining = Set<String>.from(pendingPickupStopIds);

    while (remaining.isNotEmpty) {
      // Find nearest stop to current position
      var nearest = remaining.first;
      var minDistance = double.infinity;

      for (var stopId in remaining) {
        final result = findShortestPath(currentStop, stopId, useTime: true);
        if (result.totalTime < minDistance) {
          minDistance = result.totalTime;
          nearest = stopId;
        }
      }

      sequence.add(nearest);
      remaining.remove(nearest);
      currentStop = nearest;
    }

    return sequence;
  }

  List<String> _reconstructPath(
    Map<String, String?> previous,
    String sourceStopId,
    String destinationStopId,
  ) {
    final path = <String>[];
    var current = destinationStopId;

    while (current != null) {
      path.insert(0, current);
      if (current == sourceStopId) break;
      current = previous[current];
    }

    return path.isNotEmpty && path.first == sourceStopId
        ? path
        : [sourceStopId];
  }
}

/// Internal class for priority queue
class _DijkstraNode {
  final String stopId;
  final double cost;

  _DijkstraNode({
    required this.stopId,
    required this.cost,
  });
}
