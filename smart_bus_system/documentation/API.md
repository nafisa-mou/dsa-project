# API Documentation

## Table of Contents
1. [Authentication API](#authentication-api)
2. [Location Services API](#location-services-api)
3. [Pickup Coordination API](#pickup-coordination-api)
4. [Route Optimization API](#route-optimization-api)
5. [DSA Algorithms API](#dsa-algorithms-api)
6. [Admin API](#admin-api)
7. [Real-time APIs](#real-time-apis)

---

## Authentication API

### Firebase Authentication

#### Sign Up (Student)
```
POST /auth/student/signup
Content-Type: application/json

{
  "email": "student@university.edu",
  "password": "secure_password",
  "name": "John Doe",
  "department": "Computer Science",
  "batch": "2024"
}

Response (200 OK):
{
  "uid": "user_123",
  "email": "student@university.edu",
  "name": "John Doe",
  "token": "jwt_token_here"
}
```

#### Login
```
POST /auth/login
Content-Type: application/json

{
  "email": "student@university.edu",
  "password": "secure_password",
  "userType": "student"
}

Response (200 OK):
{
  "uid": "user_123",
  "token": "jwt_token_here",
  "userType": "student",
  "expiresIn": 3600
}
```

#### Logout
```
POST /auth/logout
Authorization: Bearer jwt_token

Response (200 OK):
{
  "message": "Logged out successfully"
}
```

---

## Location Services API

### LocationService

#### Update Bus Location
```dart
Future<void> updateBusLocation(
  String busId,
  double latitude,
  double longitude, {
  double? speed,
  double? heading,
}) async
```

**Usage:**
```dart
final locationService = LocationService();
await locationService.updateBusLocation(
  'bus_001',
  13.0059,
  77.5761,
  speed: 25.5,
  heading: 45.0,
);
```

**Firebase Update:**
```
/buses_live_locations/bus_001
{
  "entityId": "bus_001",
  "entityType": "bus",
  "latitude": 13.0059,
  "longitude": 77.5761,
  "timestamp": "2024-01-20T15:05:23Z",
  "speed": 25.5,
  "heading": 45.0,
  "isActive": true
}
```

#### Track Bus Location (Stream)
```dart
Stream<LiveLocation> trackBusLocation(String busId)
```

**Usage:**
```dart
final locationService = LocationService();
locationService.trackBusLocation('bus_001').listen((location) {
  print('Bus at: ${location.latitude}, ${location.longitude}');
});
```

#### Update Student Location
```dart
Future<void> updateStudentLocation(
  String studentId,
  double latitude,
  double longitude,
) async
```

**Note:** Only called when student has active pickup request

#### Stop Location Sharing
```dart
Future<void> stopLocationSharing(String studentId) async
```

**Triggers:**
- Student cancels pickup request
- Pickup is completed
- Timeout after 15 minutes inactivity
- Student manually stops sharing

#### Calculate Distance
```dart
double calculateDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
)

// Returns: Distance in kilometers
```

#### Calculate ETA
```dart
Future<double> calculateETA(
  double fromLat,
  double fromLon,
  double toLat,
  double toLon,
) async

// Returns: Estimated minutes
```

---

## Pickup Coordination API

### PickupCoordinationService

#### Create Pickup Request
```dart
Future<PickupRequestModel> createPickupRequest({
  required String studentId,
  required String studentName,
  required String studentPhone,
  required double pickupLatitude,
  required double pickupLongitude,
  PickupPriority priority = PickupPriority.medium,
  DateTime? desiredArrivalTime,
}) async
```

**Example:**
```dart
final pickupService = PickupCoordinationService();
final request = await pickupService.createPickupRequest(
  studentId: 'std_123',
  studentName: 'John Doe',
  studentPhone: '+91-9876543210',
  pickupLatitude: 13.0059,
  pickupLongitude: 77.5761,
  priority: PickupPriority.high,
);
```

**Response:**
```json
{
  "id": "req_1234",
  "studentId": "std_123",
  "studentName": "John Doe",
  "studentPhone": "+91-9876543210",
  "pickupLatitude": 13.0059,
  "pickupLongitude": 77.5761,
  "requestTime": "2024-01-20T15:00:00Z",
  "status": "pending",
  "assignedBusId": null,
  "assignedDriverId": null,
  "estimatedArrivalMinutes": null
}
```

#### Get Next Pickup
```dart
PickupRequest? getNextPickupToAssign()
```

**Returns:** Highest priority request from scheduler (O(1) operation)

#### Assign Bus to Pickup
```dart
Future<void> assignBusToPickup(
  String requestId,
  String busId,
  String driverId,
  double estimatedArrivalMinutes,
) async
```

**Firebase Update:**
```
/pickup_requests/req_1234
{
  "status": "accepted",
  "assignedBusId": "bus_001",
  "assignedDriverId": "drv_123",
  "estimatedArrivalMinutes": 8
}
```

#### Complete Pickup Request
```dart
Future<void> completePickupRequest(
  String requestId,
  String studentId,
  String busId,
) async
```

**Firebase Update:**
```
/pickup_requests/req_1234
{
  "status": "completed",
  "completedTime": "2024-01-20T15:08:00Z"
}

/live_locations/std_123
{
  "isActive": false  // Stop sharing
}
```

#### Cancel Pickup Request
```dart
Future<void> cancelPickupRequest(String requestId) async
```

#### Get Pending Requests
```dart
Future<List<PickupRequestModel>> getPendingPickupRequests() async
```

**Query:**
```
GET /pickup_requests?where=status&equalTo=pending
```

#### Update Bus Location for Scheduler
```dart
void updateBusLocationForScheduler(
  double busLatitude,
  double busLongitude,
)
```

**Effect:** Recalculates priorities based on new bus position

#### Expire Old Requests
```dart
Future<void> expireOldPickupRequests() async
```

**Logic:**
- Finds requests older than 15 minutes
- Sets status to "expired"
- Removes from priority queue
- Runs periodically (every 5 minutes)

---

## Route Optimization API

### RouteOptimizationService

#### Initialize Bus Network
```dart
Future<void> initializeBusNetwork() async
```

**Loads:**
- All bus stops from Firestore
- All road connections
- Builds graph structure
- Called at app startup

#### Calculate Shortest Route
```dart
Future<DijkstraResult> calculateShortestRoute(
  String fromStopId,
  String toStopId, {
  bool optimizeForTime = true,
}) async
```

**Response:**
```dart
DijkstraResult {
  destinationStopId: 'stop_5',
  totalDistance: 8.5,      // km
  totalTime: 25.0,         // minutes
  routePath: ['stop_1', 'stop_2', 'stop_3', 'stop_5'],
  distances: {...},
  times: {...}
}
```

#### Optimize Pickup Sequence
```dart
Future<List<String>> optimizePickupSequence(
  String busCurrentStopId,
  List<String> pendingPickupStopIds,
) async
```

**Algorithm:** Greedy Nearest-Neighbor
- Finds closest stop to current position
- From there, finds closest to next
- Repeats until all stops visited
- Result: ~70% of optimal solution quickly

**Example:**
```dart
final sequence = await routeService.optimizePickupSequence(
  'stop_main_gate',
  ['stop_hostel_a', 'stop_hostel_b', 'stop_library'],
);
// Returns: ['stop_hostel_a', 'stop_library', 'stop_hostel_b']
```

#### Calculate ETA to Stop
```dart
Future<double> calculateETAToStop(
  String busCurrentStopId,
  String destinationStopId,
) async

// Returns: Minutes
```

#### Get Nearest Stops
```dart
List<BusStop> getNearestStops(
  double latitude,
  double longitude, {
  required int count,
})
```

**Example:**
```dart
final nearest = routeService.getNearestStops(
  13.0059,
  77.5761,
  count: 5,
);
// Returns: List of 5 nearest BusStop objects
```

#### Check Network Connectivity
```dart
bool isNetworkConnected()
```

**Returns:** true if all stops are reachable from any stop

#### Get Network Statistics
```dart
Map<String, dynamic> getNetworkStats()
```

**Response:**
```dart
{
  'totalStops': 45,
  'totalRoads': 120,
  'isConnected': true,
  'components': 1
}
```

---

## DSA Algorithms API

### Graph Operations

#### Add Bus Stop
```dart
void addStop(BusStop stop)
```

#### Add Road Connection
```dart
void addRoad(RoadEdge edge)
```

#### Get Neighbors
```dart
List<BusStop>? getNeighbors(String stopId)
```

#### Check Connectivity
```dart
bool hasEdge(String fromId, String toId)
```

### Dijkstra Algorithm

#### Find Shortest Path
```dart
DijkstraResult findShortestPath(
  String sourceStopId,
  String destinationStopId, {
  bool useTime = false,
})
```

**Time Complexity:** O((V + E) log V)
**Space Complexity:** O(V)

#### Find All Shortest Paths
```dart
Map<String, DijkstraResult> findAllShortestPaths(
  String sourceStopId, {
  bool useTime = false,
})
```

#### Find K Nearest Stops
```dart
List<BusStop> findNearestStops(
  LatLng location, {
  required int k,
})
```

### Priority Queue Scheduler

#### Add Request
```dart
void addPickupRequest(PickupRequest request)
```

**Time:** O(log n)

#### Get Next Request
```dart
PickupRequest? getNextPickup()
```

**Time:** O(1) amortized

#### Remove Request
```dart
bool removePickupRequest(String requestId)
```

#### Get All Pending
```dart
List<PickupRequest> getAllPendingRequests()
```

**Sorted by priority**

### Graph Traversal

#### BFS Traversal
```dart
List<String> bfs(String startStopId)
```

**Time:** O(V + E)

#### DFS Traversal
```dart
List<String> dfs(String startStopId)
```

**Time:** O(V + E)

#### Find Connected Components
```dart
List<List<String>> findConnectedComponents()
```

#### Detect Cycles
```dart
bool hasCycle()
```

#### Check Path Existence
```dart
bool hasPath(String fromStopId, String toStopId)
```

### HashMap Storage

#### Put Student
```dart
void putStudent(Student student)
```

#### Get Student by ID
```dart
Student? getStudent(String studentId)  // O(1)
```

#### Get Student by Email
```dart
Student? getStudentByEmail(String email)  // O(1)
```

#### Get All Students in Department
```dart
List<Student> getStudentsByDepartment(String department)
```

#### Put Driver
```dart
void putDriver(Driver driver)  // O(1)
```

#### Put Bus
```dart
void putBus(Bus bus)  // O(1)
```

#### Get Buses by Driver
```dart
List<Bus> getBusesByDriver(String driverId)  // O(1)
```

#### Search
```dart
Map<String, dynamic> search(String query)
```

**Returns:** Matched students, drivers, and buses

---

## Admin API

### System Monitoring

#### Get System Statistics
```
GET /admin/statistics

Response:
{
  "activeBuses": 12,
  "totalStudents": 2450,
  "totalDrivers": 15,
  "pendingRequests": 23,
  "completedToday": 450,
  "averageWaitTime": 8.5,
  "systemHealth": 0.98
}
```

#### Get Bus Status
```
GET /admin/buses

Response: [
  {
    "id": "bus_001",
    "routeName": "Main Campus",
    "driverId": "drv_123",
    "status": "in_transit",
    "latitude": 13.0059,
    "longitude": 77.5761,
    "occupancy": 25,
    "capacity": 40,
    "nextStop": "Library",
    "eta": "5 minutes"
  },
  ...
]
```

#### Get Analytics
```
GET /admin/analytics?from=2024-01-20&to=2024-01-21

Response:
{
  "totalRequests": 1250,
  "completedRequests": 1198,
  "cancelledRequests": 52,
  "avgWaitTime": 8.3,
  "peakHours": [
    {"hour": 8, "requests": 320},
    {"hour": 12, "requests": 285},
    ...
  ],
  "busUtilization": 0.82,
  "departmentBreakdown": {...}
}
```

---

## Real-time APIs

### Realtime Database Paths

#### Bus Locations Stream
```
/buses_live_locations/{busId}
```

**Subscribe:**
```dart
databaseReference
  .child('buses_live_locations')
  .child(busId)
  .onValue
  .listen((event) {
    // Update UI with new location
  });
```

#### Student Locations Stream
```
/student_live_locations/{studentId}
```

**Subscribe:**
```dart
databaseReference
  .child('student_live_locations')
  .child(studentId)
  .onValue
  .listen((event) {
    // Update driver's map with student position
  });
```

#### Active Pickups Stream
```
/pickup_requests_active/{requestId}
```

**Subscribe:**
```dart
databaseReference
  .child('pickup_requests_active')
  .onChildAdded
  .listen((event) {
    // New pickup request
  });
```

---

## Error Handling

### Standard Error Responses

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Student location is invalid",
    "details": "Latitude must be between -90 and 90",
    "timestamp": "2024-01-20T15:00:00Z"
  }
}
```

### Common Error Codes

| Code | Status | Meaning |
|------|--------|---------|
| INVALID_REQUEST | 400 | Invalid input parameters |
| UNAUTHORIZED | 401 | Authentication failed |
| FORBIDDEN | 403 | Access denied |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Resource conflict |
| RATE_LIMITED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |

---

**Last Updated**: January 2024
