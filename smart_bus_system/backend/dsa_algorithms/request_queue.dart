/// DSA: Queue Data Structure for Request Processing
/// 
/// Used for:
/// - FIFO processing of bus requests
/// - Student cancellation requests
/// - Driver action queue
/// - Analytics event queue

class QueueRequest {
  final String id;
  final String type; // 'pickup', 'cancel', 'complete', 'emergency'
  final String userId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  bool processed;

  QueueRequest({
    required this.id,
    required this.type,
    required this.userId,
    required this.data,
    DateTime? createdAt,
    this.processed = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// FIFO Queue Implementation for Request Processing
class RequestQueue {
  final List<QueueRequest> _queue = [];
  int _processedCount = 0;

  /// Enqueue a request
  void enqueue(QueueRequest request) {
    _queue.add(request);
  }

  /// Dequeue (remove and return first request)
  QueueRequest? dequeue() {
    if (_queue.isEmpty) return null;
    final request = _queue.removeAt(0);
    request.processed = true;
    _processedCount++;
    return request;
  }

  /// Peek at first request without removing
  QueueRequest? peek() {
    if (_queue.isEmpty) return null;
    return _queue.first;
  }

  /// Get all pending requests
  List<QueueRequest> getAllPending() {
    return _queue.where((r) => !r.processed).toList();
  }

  /// Get requests by type
  List<QueueRequest> getRequestsByType(String type) {
    return _queue.where((r) => r.type == type && !r.processed).toList();
  }

  /// Remove a specific request by ID
  bool removeRequest(String requestId) {
    final index = _queue.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;
    _queue.removeAt(index);
    return true;
  }

  /// Get request by ID
  QueueRequest? getRequestById(String requestId) {
    return _queue.cast<QueueRequest?>().firstWhere(
          (r) => r?.id == requestId,
          orElse: () => null,
        );
  }

  /// Get queue size
  int get size => _queue.length;

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Clear queue
  void clear() {
    _queue.clear();
  }

  /// Get processing statistics
  Map<String, dynamic> getStats() {
    final typeCount = <String, int>{};

    for (var request in _queue) {
      typeCount[request.type] = (typeCount[request.type] ?? 0) + 1;
    }

    return {
      'totalPending': _queue.length,
      'totalProcessed': _processedCount,
      'byType': typeCount,
      'averageWaitTimeMinutes': _calculateAverageWaitTime(),
    };
  }
dsfsdfgsfhf
  double _calculateAverageWaitTime() {
    if (_queue.isEmpty) return 0;

    final now = DateTime.now();
    final totalWaitTime = _queue.fold<int>(
      0,
      (sum, request) =>
          sum + now.difference(request.createdAt).inSeconds,
    );

    return totalWaitTime / _queue.length / 60;
  }
}

/// Alternative: Priority-based request processing queue
class PriorityRequestQueue {
  final List<QueueRequest> _queue = [];
  
  final Map<String, int> _typePriority = {
    'emergency': 0,
    'cancel': 1,
    'complete': 2,
    'pickup': 3,
  };

  void enqueue(QueueRequest request) {
    _queue.add(request);
    _sortQueue();
  }

  QueueRequest? dequeue() {
    if (_queue.isEmpty) return null;
    final request = _queue.removeAt(0);
    request.processed = true;
    return request;
  }

  QueueRequest? peek() {
    if (_queue.isEmpty) return null;
    return _queue.first;
  }

  void _sortQueue() {
    _queue.sort((a, b) {
      final aPriority = _typePriority[a.type] ?? 999;
      final bPriority = _typePriority[b.type] ?? 999;
      return aPriority.compareTo(bPriority);
    });
  }

  List<QueueRequest> getAllPending() =>
      _queue.where((r) => !r.processed).toList();

  int get size => _queue.length;

  bool get isEmpty => _queue.isEmpty;

  void clear() => _queue.clear();
}
