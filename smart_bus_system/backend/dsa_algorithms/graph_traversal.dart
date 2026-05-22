/// DSA: BFS and DFS for Graph Traversal
/// 
/// Used for:
/// - Finding connected bus stops
/// - Analyzing network connectivity
/// - Checking if all stops are reachable
/// - Finding paths and cycles

import 'graph_model.dart';
import 'dart:collection';

class GraphTraversal {
  final BusNetworkGraph graph;

  GraphTraversal(this.graph);

  /// Breadth-First Search (BFS) from a starting stop
  List<String> bfs(String startStopId) {
    final visited = <String>{};
    final queue = Queue<String>();
    final result = <String>[];

    queue.add(startStopId);
    visited.add(startStopId);

    while (queue.isNotEmpty) {
      final stopId = queue.removeFirst();
      result.add(stopId);

      // Get all neighbors
      final edges = graph.getEdgesFrom(stopId);
      if (edges != null) {
        for (var edge in edges) {
          if (!visited.contains(edge.toStopId)) {
            visited.add(edge.toStopId);
            queue.add(edge.toStopId);
          }
        }
      }
    }

    return result;
  }

  /// Depth-First Search (DFS) from a starting stop
  List<String> dfs(String startStopId) {
    final visited = <String>{};
    final result = <String>[];

    _dfsHelper(startStopId, visited, result);

    return result;
  }

  /// Find all connected components
  List<List<String>> findConnectedComponents() {
    final visited = <String>{};
    final components = <List<String>>[];

    for (var stop in graph.getAllStops()) {
      if (!visited.contains(stop.id)) {
        final component = _getConnectedComponent(stop.id, visited);
        components.add(component);
      }
    }

    return components;
  }

  /// Check if all stops are connected
  bool isConnected() {
    if (graph.getStopCount() == 0) return true;

    final allStops = graph.getAllStops();
    final visited = bfs(allStops.first.id).toSet();

    return visited.length == graph.getStopCount();
  }

  /// Find all reachable stops from a given stop
  Set<String> getReachableStops(String startStopId) {
    final visited = <String>{};
    final queue = Queue<String>();

    queue.add(startStopId);
    visited.add(startStopId);

    while (queue.isNotEmpty) {
      final stopId = queue.removeFirst();
      final edges = graph.getEdgesFrom(stopId);

      if (edges != null) {
        for (var edge in edges) {
          if (!visited.contains(edge.toStopId)) {
            visited.add(edge.toStopId);
            queue.add(edge.toStopId);
          }
        }
      }
    }

    return visited;
  }

  /// Find if there's a path between two stops
  bool hasPath(String fromStopId, String toStopId) {
    if (fromStopId == toStopId) return true;

    final visited = <String>{};
    final queue = Queue<String>();

    queue.add(fromStopId);
    visited.add(fromStopId);

    while (queue.isNotEmpty) {
      final stopId = queue.removeFirst();

      if (stopId == toStopId) return true;

      final edges = graph.getEdgesFrom(stopId);
      if (edges != null) {
        for (var edge in edges) {
          if (!visited.contains(edge.toStopId)) {
            visited.add(edge.toStopId);
            queue.add(edge.toStopId);
          }
        }
      }
    }

    return false;
  }

  /// Find all paths between two stops (DFS-based)
  List<List<String>> findAllPaths(String fromStopId, String toStopId) {
    final paths = <List<String>>[];
    final visited = <String>{};
    final currentPath = <String>[];

    _findAllPathsHelper(fromStopId, toStopId, visited, currentPath, paths);

    return paths;
  }

  /// Detect cycle in the graph
  bool hasCycle() {
    final visited = <String>{};
    final recursionStack = <String>{};

    for (var stop in graph.getAllStops()) {
      if (!visited.contains(stop.id)) {
        if (_hasCycleHelper(stop.id, visited, recursionStack)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get strongly connected components (for directed graph analysis)
  List<List<String>> getStronglyConnectedComponents() {
    final visited = <String>{};
    final stack = <String>[];
    final components = <List<String>>[];

    // Step 1: Do DFS and fill stack
    for (var stop in graph.getAllStops()) {
      if (!visited.contains(stop.id)) {
        _dfsForSCC(stop.id, visited, stack);
      }
    }

    // Step 2: Create transpose graph
    visited.clear();

    // Step 3: Do DFS on transpose
    while (stack.isNotEmpty) {
      final stopId = stack.removeLast();

      if (!visited.contains(stopId)) {
        final component = _getConnectedComponent(stopId, visited);
        components.add(component);
      }
    }

    return components;
  }

  // === PRIVATE HELPER METHODS ===

  void _dfsHelper(
    String stopId,
    Set<String> visited,
    List<String> result,
  ) {
    visited.add(stopId);
    result.add(stopId);

    final edges = graph.getEdgesFrom(stopId);
    if (edges != null) {
      for (var edge in edges) {
        if (!visited.contains(edge.toStopId)) {
          _dfsHelper(edge.toStopId, visited, result);
        }
      }
    }
  }

  List<String> _getConnectedComponent(
    String startStopId,
    Set<String> visited,
  ) {
    final component = <String>[];
    final queue = Queue<String>();

    queue.add(startStopId);
    visited.add(startStopId);

    while (queue.isNotEmpty) {
      final stopId = queue.removeFirst();
      component.add(stopId);

      final edges = graph.getEdgesFrom(stopId);
      if (edges != null) {
        for (var edge in edges) {
          if (!visited.contains(edge.toStopId)) {
            visited.add(edge.toStopId);
            queue.add(edge.toStopId);
          }
        }
      }
    }

    return component;
  }

  void _findAllPathsHelper(
    String current,
    String destination,
    Set<String> visited,
    List<String> currentPath,
    List<List<String>> paths,
  ) {
    visited.add(current);
    currentPath.add(current);

    if (current == destination) {
      paths.add(List<String>.from(currentPath));
    } else {
      final edges = graph.getEdgesFrom(current);
      if (edges != null) {
        for (var edge in edges) {
          if (!visited.contains(edge.toStopId)) {
            _findAllPathsHelper(
              edge.toStopId,
              destination,
              visited,
              currentPath,
              paths,
            );
          }
        }
      }
    }

    visited.remove(current);
    currentPath.removeLast();
  }

  bool _hasCycleHelper(
    String stopId,
    Set<String> visited,
    Set<String> recursionStack,
  ) {
    visited.add(stopId);
    recursionStack.add(stopId);

    final edges = graph.getEdgesFrom(stopId);
    if (edges != null) {
      for (var edge in edges) {
        if (!visited.contains(edge.toStopId)) {
          if (_hasCycleHelper(edge.toStopId, visited, recursionStack)) {
            return true;
          }
        } else if (recursionStack.contains(edge.toStopId)) {
          return true;
        }
      }
    }

    recursionStack.remove(stopId);
    return false;
  }

  void _dfsForSCC(
    String stopId,
    Set<String> visited,
    List<String> stack,
  ) {
    visited.add(stopId);

    final edges = graph.getEdgesFrom(stopId);
    if (edges != null) {
      for (var edge in edges) {
        if (!visited.contains(edge.toStopId)) {
          _dfsForSCC(edge.toStopId, visited, stack);
        }
      }
    }

    stack.add(stopId);
  }
}
