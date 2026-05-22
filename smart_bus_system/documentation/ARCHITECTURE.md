# System Architecture Documentation

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                      │
├──────────────────┬──────────────────┬──────────────────────┤
│  Student App     │   Driver App     │   Admin Dashboard    │
│  (Flutter)       │   (Flutter)      │   (Flutter Web)      │
└────────┬─────────┴────────┬─────────┴────────────┬────────┘
         │                  │                      │
         ├──────────────────┴──────────────────────┤
         │                                         │
         ▼                                         ▼
┌──────────────────────────────┐    ┌─────────────────────────┐
│   Service Layer              │    │   State Management      │
├──────────────────────────────┤    ├─────────────────────────┤
│ • LocationService            │    │ • Provider              │
│ • PickupCoordinationService  │    │ • Riverpod              │
│ • RouteOptimizationService   │    │ • Local Providers       │
└────────────┬─────────────────┘    └─────────────┬───────────┘
             │                                    │
             └────────────────┬───────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Backend Services Layer                         │
├──────────────────┬──────────────────┬─────────────────────┤
│  DSA Algorithms  │   Firebase       │   External APIs     │
├──────────────────┼──────────────────┼─────────────────────┤
│ • Graph Model    │ • Authentication │ • Google Maps API   │
│ • Dijkstra       │ • Firestore      │ • Places API        │
│ • Priority Queue │ • Realtime DB    │ • Directions API    │
│ • Request Queue  │ • Cloud Msg      │ • Geolocation API   │
│ • Hash Maps      │ • Cloud Storage  │                     │
│ • BFS/DFS        │ • Cloud Func     │                     │
└──────────────────┴──────────────────┴─────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│              Data & Storage Layer                           │
├──────────────────────────────────────────────────────────────┤
│          Firebase (Firestore + Realtime Database)           │
└──────────────────────────────────────────────────────────────┘
```

---

## Component Architecture

### 1. Student App Architecture

```
StudentApp
├── Screens
│   ├── AuthScreen (Login/Register)
│   ├── HomeScreen
│   │   ├── TrackingScreen (Bus tracking with Google Maps)
│   │   ├── PickupScreen (Request pickup)
│   │   ├── HistoryScreen (Trip history)
│   │   └── ProfileScreen (User profile)
│   ├── PickupDetailsScreen
│   └── NotificationScreen
├── Providers (State Management)
│   ├── AuthProvider (User authentication)
│   ├── BusTrackingProvider (Bus locations)
│   ├── PickupProvider (Pickup requests)
│   ├── LocationProvider (User GPS)
│   └── NotificationProvider (Push notifications)
├── Services
│   ├── LocationService (GPS tracking)
│   ├── PickupCoordinationService (Pickup requests)
│   ├── AuthService (Firebase Auth)
│   └── NotificationService (FCM)
├── Models
│   ├── Student
│   ├── Bus
│   ├── PickupRequest
│   └── Trip
└── Widgets (Reusable Components)
    ├── BusMarker
    ├── StudentMarker
    ├── PickupCard
    └── TrackingPanel
```

### 2. Driver App Architecture

```
DriverApp
├── Screens
│   ├── AuthScreen (Driver Login)
│   ├── HomeScreen
│   │   ├── RouteScreen (Current route navigation)
│   │   ├── PickupScreen (Manage pickups)
│   │   ├── PassengersScreen (Onboard list)
│   │   └── ProfileScreen
│   ├── PickupDetailScreen
│   └── StudentProfileScreen
├── Providers (State Management)
│   ├── AuthProvider
│   ├── DriverStatusProvider
│   ├── PickupProvider (Available pickups)
│   ├── RouteProvider (Current route)
│   └── LocationProvider (GPS tracking)
├── Services
│   ├── LocationService (Continuous GPS)
│   ├── PickupCoordinationService
│   ├── RouteOptimizationService
│   ├── NotificationService
│   └── BackgroundService (Foreground service for GPS)
├── Models
│   ├── Driver
│   ├── Trip
│   ├── PickupRequest
│   └── Student
└── Widgets (Reusable Components)
    ├── RouteMap
    ├── PickupCard
    ├── StudentCard
    └── TripSummary
```

### 3. Admin Dashboard Architecture

```
AdminDashboard
├── Screens
│   ├── AuthScreen (Admin Login)
│   ├── DashboardOverview
│   │   ├── SystemStats
│   │   ├── ActiveBuses
│   │   ├── PendingRequests
│   │   └── QuickActions
│   ├── BusManagementScreen
│   │   ├── BusList
│   │   ├── BusDetails
│   │   └── RouteEditor
│   ├── StudentManagementScreen
│   │   ├── StudentList
│   │   ├── StudentDetails
│   │   └── BulkImport
│   ├── PickupMonitorScreen
│   │   ├── ActiveRequests
│   │   ├── RequestDetails
│   │   └── ManualAssignment
│   ├── AnalyticsScreen
│   │   ├── Charts & Graphs
│   │   ├── Reports
│   │   └── Export
│   └── SettingsScreen
├── Providers
│   ├── AdminAuthProvider
│   ├── BusProvider
│   ├── StudentProvider
│   ├── PickupProvider
│   ├── AnalyticsProvider
│   └── SystemProvider
├── Services
│   ├── AdminService
│   ├── AnalyticsService
│   ├── DataExportService
│   ├── ReportService
│   └── SystemManagementService
├── Models
│   ├── AdminUser
│   ├── SystemMetrics
│   ├── Report
│   └── AnalyticsData
└── Widgets
    ├── DataTable
    ├── Charts
    ├── Filters
    └── ExportDialog
```

---

## DSA Layer Architecture

### Graph Model (Bus Network)
```
BusNetworkGraph
├── stops: Map<String, BusStop>
│   └── BusStop (id, name, location, description)
│       └── LatLng (latitude, longitude)
│
└── adjacencyList: Map<String, List<RoadEdge>>
    └── RoadEdge (fromStopId, toStopId, distance, time)
```

### Route Optimization Flow
```
Student Location (LatLng)
    ↓
[FindNearestStops] (Dijkstra)
    ↓
Available Bus Stops (K-nearest)
    ↓
[PickupScheduler] (Priority Queue)
    ↓
Prioritized Requests
    ↓
[OptimizePickupSequence] (Greedy Nearest-Neighbor)
    ↓
Optimal Pickup Order (List<String>)
    ↓
[Dijkstra] (Calculate Times)
    ↓
ETA & Routes
    ↓
Driver → Student
```

### Pickup Prioritization Algorithm
```
Priority Score Calculation:
├── Base Priority (1000 for critical, 700 for high, etc.)
├── + Wait Time Factor (older = higher score)
├── + Distance Factor (closer = higher, but not too close)
├── + Desired Arrival Time Factor (urgent times)
└── = Final Priority Score

Result: Sorted List of Pickup Requests
```

---

## Data Flow Diagrams

### Pickup Request Flow
```
Student
   ↓
[RequestPickup] (Location + Department)
   ↓
Firebase Firestore (Save Request)
   ↓
PickupScheduler (Add to Priority Queue)
   ↓
Driver App (Notification)
   ↓
Driver Decision (Accept/Decline)
   ↓
[AssignBus] (If Accepted)
   ↓
Calculate ETA (Dijkstra)
   ↓
Firebase Update (ETA + Bus Info)
   ↓
Student Notification (Bus assigned)
   ↓
Student Shares Location (during pickup only)
   ↓
Realtime Database (Location stream)
   ↓
Driver Map (Live student position)
   ↓
Student Boards
   ↓
[CompletePickup] (Update Firebase)
   ↓
Stop Location Sharing (Privacy)
```

### Bus Tracking Flow
```
Bus GPS (Device)
   ↓
[LocationService.updateBusLocation]
   ↓
Realtime Database (Live Update)
   ↓
Student App (Stream Subscription)
   ↓
Google Maps (Marker Animation)
   ↓
ETA Calculation (Dijkstra from current stop)
   ↓
Display on Map
```

---

## Service Layer Design

### LocationService
- **Purpose**: Manage GPS tracking and location updates
- **Methods**:
  - `trackBusLocation(busId)`: Stream bus positions
  - `updateBusLocation(lat, lng)`: Update GPS
  - `stopLocationSharing(studentId)`: Privacy protection
  - `getLocation(entityId)`: Fetch from cache or DB
  - `calculateDistance(lat1, lng1, lat2, lng2)`: Distance calculation
  - `calculateETA(from, to)`: Time estimation

### PickupCoordinationService
- **Purpose**: Manage pickup requests and assignment
- **Methods**:
  - `createPickupRequest(...)`: Create new request
  - `getNextPickupToAssign()`: Get highest priority
  - `assignBusToPickup(...)`: Assign bus
  - `completePickupRequest(...)`: Mark as done
  - `cancelPickupRequest(requestId)`: Cancel request
  - `updateBusLocationForScheduler(...)`: Update priorities

### RouteOptimizationService
- **Purpose**: Calculate routes and optimizations
- **Methods**:
  - `initializeBusNetwork()`: Load from Firebase
  - `calculateShortestRoute(from, to)`: Dijkstra
  - `optimizePickupSequence(...)`: Greedy nearest-neighbor
  - `calculateETAToStop(from, to)`: ETA calculation
  - `getReachableStops(from)`: BFS traversal
  - `calculateOptimalRoute(start, stops)`: Multi-stop route

---

## State Management

### Using Provider + Riverpod

```dart
// Example: BusTrackingProvider (Student App)
final busTrackingProvider = StreamProvider.family((ref, busId) async* {
  final locationService = ref.watch(locationServiceProvider);
  yield* locationService.trackBusLocation(busId);
});

// Example: PickupProvider
final pickupProvider = StateNotifierProvider((ref) {
  return PickupNotifier(ref.watch(pickupServiceProvider));
});
```

---

## Caching Strategy

### Cache Layers
1. **In-Memory Cache** (HashMap)
   - Students, Drivers, Buses
   - Live locations
   - O(1) access time

2. **Local Database** (Hive/SQLite)
   - Offline student/driver data
   - Trip history

3. **Firebase Cache**
   - Automatic through Firestore
   - Configurable offline persistence

---

## Error Handling

### Layered Error Handling
```dart
try {
  // API call
} on FirebaseException catch (e) {
  // Firebase-specific errors
} on LocationException catch (e) {
  // Location-specific errors
} on NetworkException catch (e) {
  // Network errors
} catch (e) {
  // Generic errors
} finally {
  // Cleanup
}
```

---

## Performance Optimization

### Techniques Used
1. **Lazy Loading**: Load data on demand
2. **Pagination**: Load requests in pages
3. **Caching**: Cache frequently accessed data
4. **Indexing**: Firebase Firestore indexes
5. **Compression**: Compress location data
6. **Batching**: Batch database updates

### Optimization Metrics
- **DSA Operations**: <100ms for most operations
- **Firebase Queries**: <500ms average
- **Map Updates**: <200ms for marker updates
- **Total App Startup**: <2 seconds

---

## Security Architecture

### Authentication Flow
```
User Input (Email/Password)
    ↓
Firebase Authentication
    ↓
JWT Token Generation
    ↓
Token Storage (Secure Storage)
    ↓
API Requests (Token in Header)
    ↓
Backend Validation
    ↓
Response
```

### Data Encryption
- In-transit: TLS/HTTPS
- At-rest: Firebase encryption
- Sensitive data: Additional AES-256

### Privacy Controls
- Location shared only during active pickup
- Auto-stop after timeout
- User can revoke anytime
- No permanent location history

---

**Last Updated**: January 2024
