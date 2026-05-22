/// Firebase Configuration and Data Models
/// 
/// Firebase Collections Schema:
/// - users/ {userId}
/// - students/ {studentId}
/// - drivers/ {driverId}
/// - buses/ {busId}
/// - pickup_requests/ {requestId}
/// - live_locations/ {entityId}
/// - trips/ {tripId}
/// - bus_stops/ {stopId}
/// - routes/ {routeId}

class FirebaseConfig {
  // Firebase project configuration
  static const String projectId = 'smart-bus-system';
  static const String apiKey = 'YOUR_FIREBASE_API_KEY';
  static const String appId = 'YOUR_FIREBASE_APP_ID';
  static const String messagingSenderId = 'YOUR_MESSAGING_SENDER_ID';
  
  // Firestore collections
  static const String collectionUsers = 'users';
  static const String collectionStudents = 'students';
  static const String collectionDrivers = 'drivers';
  static const String collectionBuses = 'buses';
  static const String collectionPickupRequests = 'pickup_requests';
  static const String collectionLiveLocations = 'live_locations';
  static const String collectionTrips = 'trips';
  static const String collectionBusStops = 'bus_stops';
  static const String collectionRoutes = 'routes';
  static const String collectionAnalytics = 'analytics';
  
  // Realtime Database paths (for live updates)
  static const String dbBusLocations = '/buses_live_locations';
  static const String dbStudentLocations = '/student_live_locations';
  static const String dbPickupRequests = '/pickup_requests_active';
  static const String dbDriverStatus = '/drivers_status';
}

/// User authentication model
class User {
  final String id;
  final String email;
  final String name;
  final String userType; // 'student', 'driver', 'admin'
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      userType: map['userType'] ?? 'student',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
    );
  }
}

/// Trip model for tracking bus journeys
class Trip {
  final String id;
  final String busId;
  final String driverId;
  final String routeName;
  final DateTime startTime;
  DateTime? endTime;
  final List<String> stopsSequence; // ordered stop IDs
  final Map<String, DateTime> stopArrivalTimes;
  List<String> studentsBoarded;
  String status; // 'scheduled', 'in_progress', 'completed'

  Trip({
    required this.id,
    required this.busId,
    required this.driverId,
    required this.routeName,
    required this.startTime,
    this.endTime,
    required this.stopsSequence,
    Map<String, DateTime>? stopArrivalTimes,
    List<String>? studentsBoarded,
    this.status = 'scheduled',
  })  : stopArrivalTimes = stopArrivalTimes ?? {},
        studentsBoarded = studentsBoarded ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busId': busId,
      'driverId': driverId,
      'routeName': routeName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'stopsSequence': stopsSequence,
      'stopArrivalTimes': stopArrivalTimes.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
      'studentsBoarded': studentsBoarded,
      'status': status,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] ?? '',
      busId: map['busId'] ?? '',
      driverId: map['driverId'] ?? '',
      routeName: map['routeName'] ?? '',
      startTime: DateTime.parse(map['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      stopsSequence: List<String>.from(map['stopsSequence'] ?? []),
      stopArrivalTimes: (map['stopArrivalTimes'] as Map?)?.map(
        (k, v) => MapEntry(k, DateTime.parse(v)),
      ) ?? {},
      studentsBoarded: List<String>.from(map['studentsBoarded'] ?? []),
      status: map['status'] ?? 'scheduled',
    );
  }
}

/// Pickup request model
class PickupRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final double pickupLatitude;
  final double pickupLongitude;
  final DateTime requestTime;
  DateTime? completedTime;
  String status; // 'pending', 'accepted', 'completed', 'cancelled', 'expired'
  String? assignedBusId;
  String? assignedDriverId;
  double? estimatedArrivalMinutes;

  PickupRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.requestTime,
    this.completedTime,
    this.status = 'pending',
    this.assignedBusId,
    this.assignedDriverId,
    this.estimatedArrivalMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentPhone': studentPhone,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'requestTime': requestTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'status': status,
      'assignedBusId': assignedBusId,
      'assignedDriverId': assignedDriverId,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
    };
  }

  factory PickupRequestModel.fromMap(Map<String, dynamic> map) {
    return PickupRequestModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentPhone: map['studentPhone'] ?? '',
      pickupLatitude: map['pickupLatitude'] ?? 0.0,
      pickupLongitude: map['pickupLongitude'] ?? 0.0,
      requestTime: DateTime.parse(map['requestTime'] ?? DateTime.now().toIso8601String()),
      completedTime: map['completedTime'] != null ? DateTime.parse(map['completedTime']) : null,
      status: map['status'] ?? 'pending',
      assignedBusId: map['assignedBusId'],
      assignedDriverId: map['assignedDriverId'],
      estimatedArrivalMinutes: map['estimatedArrivalMinutes'],
    );
  }
}

/// Live location model (for real-time updates)
class LiveLocation {
  final String entityId; // studentId, busId, or driverId
  final String entityType; // 'student', 'bus', 'driver'
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed; // in km/h
  final double? heading; // in degrees
  bool isActive;

  LiveLocation({
    required this.entityId,
    required this.entityType,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.heading,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'entityId': entityId,
      'entityType': entityType,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'heading': heading,
      'isActive': isActive,
    };
  }

  factory LiveLocation.fromMap(Map<String, dynamic> map) {
    return LiveLocation(
      entityId: map['entityId'] ?? '',
      entityType: map['entityType'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      speed: map['speed'],
      heading: map['heading'],
      isActive: map['isActive'] ?? true,
    );
  }
}

/// Analytics event for system monitoring
class AnalyticsEvent {
  final String id;
  final String eventType; // 'pickup_request', 'bus_arrival', 'student_boarded', etc.
  final DateTime timestamp;
  final String? busId;
  final String? studentId;
  final String? driverId;
  final Map<String, dynamic> data;

  AnalyticsEvent({
    required this.id,
    required this.eventType,
    required this.timestamp,
    this.busId,
    this.studentId,
    this.driverId,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventType': eventType,
      'timestamp': timestamp.toIso8601String(),
      'busId': busId,
      'studentId': studentId,
      'driverId': driverId,
      'data': data,
    };
  }

  factory AnalyticsEvent.fromMap(Map<String, dynamic> map) {
    return AnalyticsEvent(
      id: map['id'] ?? '',
      eventType: map['eventType'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      busId: map['busId'],
      studentId: map['studentId'],
      driverId: map['driverId'],
      data: map['data'] ?? {},
    );
  }
}
