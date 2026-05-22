/// DSA: HashMap for O(1) Fast Lookups
/// 
/// Used for:
/// - Fast student lookup by ID
/// - Driver lookup by ID
/// - Live location tracking
/// - Active bus tracking
/// - Cache management

/// Student data with live location
class Student {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String batch;
  double? liveLatitude;
  double? liveLongitude;
  DateTime? lastLocationUpdate;
  bool isLocationSharing;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.batch,
    this.liveLatitude,
    this.liveLongitude,
    this.lastLocationUpdate,
    this.isLocationSharing = false,
  });

  void updateLiveLocation(double lat, double lng) {
    liveLatitude = lat;
    liveLongitude = lng;
    lastLocationUpdate = DateTime.now();
  }

  void stopLocationSharing() {
    isLocationSharing = false;
    liveLatitude = null;
    liveLongitude = null;
  }
}

/// Driver data with live location and status
class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  double? liveLatitude;
  double? liveLongitude;
  DateTime? lastLocationUpdate;
  String status; // 'available', 'on_duty', 'offline'
  int totalTrips;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    this.liveLatitude,
    this.liveLongitude,
    this.lastLocationUpdate,
    this.status = 'offline',
    this.totalTrips = 0,
  });

  void updateLiveLocation(double lat, double lng) {
    liveLatitude = lat;
    liveLongitude = lng;
    lastLocationUpdate = DateTime.now();
  }

  void updateStatus(String newStatus) {
    status = newStatus;
  }
}

/// Bus data with live tracking
class Bus {
  final String id;
  final String routeName;
  final String registrationNumber;
  final String driverId;
  double? liveLatitude;
  double? liveLongitude;
  DateTime? lastLocationUpdate;
  String status; // 'available', 'in_transit', 'maintenance'
  int capacity;
  int currentOccupancy;
  List<String> onBoardStudents;

  Bus({
    required this.id,
    required this.routeName,
    required this.registrationNumber,
    required this.driverId,
    this.liveLatitude,
    this.liveLongitude,
    this.lastLocationUpdate,
    this.status = 'available',
    this.capacity = 40,
    this.currentOccupancy = 0,
    List<String>? onBoardStudents,
  }) : onBoardStudents = onBoardStudents ?? [];

  void updateLiveLocation(double lat, double lng) {
    liveLatitude = lat;
    liveLongitude = lng;
    lastLocationUpdate = DateTime.now();
  }

  void updateStatus(String newStatus) {
    status = newStatus;
  }

  bool addStudent(String studentId) {
    if (currentOccupancy < capacity) {
      onBoardStudents.add(studentId);
      currentOccupancy++;
      return true;
    }
    return false;
  }

  bool removeStudent(String studentId) {
    final removed = onBoardStudents.remove(studentId);
    if (removed) {
      currentOccupancy--;
    }
    return removed;
  }

  double getOccupancyPercentage() => (currentOccupancy / capacity) * 100;
}

/// Main HashMap storage for all entities
class EntityHashMap {
  // Students HashMap
  final Map<String, Student> students = {};

  // Drivers HashMap
  final Map<String, Driver> drivers = {};

  // Buses HashMap
  final Map<String, Bus> buses = {};

  // Additional indices for faster lookups
  final Map<String, String> emailToStudentId = {}; // email -> studentId
  final Map<String, String> emailToDriverId = {}; // email -> driverId
  final Map<String, List<String>> driverToBuses = {}; // driverId -> [busIds]

  // === STUDENT OPERATIONS ===

  /// Add or update student
  void putStudent(Student student) {
    students[student.id] = student;
    emailToStudentId[student.email] = student.id;
  }

  /// Get student by ID - O(1)
  Student? getStudent(String studentId) => students[studentId];

  /// Get student by email - O(1)
  Student? getStudentByEmail(String email) {
    final studentId = emailToStudentId[email];
    return studentId != null ? students[studentId] : null;
  }

  /// Remove student
  bool removeStudent(String studentId) {
    final student = students.remove(studentId);
    if (student != null) {
      emailToStudentId.remove(student.email);
      return true;
    }
    return false;
  }

  /// Get all students
  List<Student> getAllStudents() => students.values.toList();

  /// Get students in a department
  List<Student> getStudentsByDepartment(String department) {
    return students.values
        .where((s) => s.department == department)
        .toList();
  }

  // === DRIVER OPERATIONS ===

  /// Add or update driver
  void putDriver(Driver driver) {
    drivers[driver.id] = driver;
    emailToDriverId[driver.email] = driver.id;
    driverToBuses.putIfAbsent(driver.id, () => []);
  }

  /// Get driver by ID - O(1)
  Driver? getDriver(String driverId) => drivers[driverId];

  /// Get driver by email - O(1)
  Driver? getDriverByEmail(String email) {
    final driverId = emailToDriverId[email];
    return driverId != null ? drivers[driverId] : null;
  }

  /// Remove driver
  bool removeDriver(String driverId) {
    final driver = drivers.remove(driverId);
    if (driver != null) {
      emailToDriverId.remove(driver.email);
      driverToBuses.remove(driverId);
      return true;
    }
    return false;
  }

  /// Get all drivers
  List<Driver> getAllDrivers() => drivers.values.toList();

  /// Get available drivers
  List<Driver> getAvailableDrivers() {
    return drivers.values
        .where((d) => d.status == 'available')
        .toList();
  }

  // === BUS OPERATIONS ===

  /// Add or update bus
  void putBus(Bus bus) {
    buses[bus.id] = bus;
    driverToBuses.putIfAbsent(bus.driverId, () => []);
    if (!driverToBuses[bus.driverId]!.contains(bus.id)) {
      driverToBuses[bus.driverId]!.add(bus.id);
    }
  }

  /// Get bus by ID - O(1)
  Bus? getBus(String busId) => buses[busId];

  /// Get buses by driver - O(1)
  List<Bus> getBusesByDriver(String driverId) {
    final busIds = driverToBuses[driverId] ?? [];
    return busIds.map((id) => buses[id]).whereType<Bus>().toList();
  }

  /// Remove bus
  bool removeBus(String busId) {
    final bus = buses.remove(busId);
    if (bus != null) {
      final busIds = driverToBuses[bus.driverId];
      busIds?.remove(busId);
      return true;
    }
    return false;
  }

  /// Get all buses
  List<Bus> getAllBuses() => buses.values.toList();

  /// Get active buses
  List<Bus> getActiveBuses() {
    return buses.values
        .where((b) => b.status == 'in_transit' || b.status == 'available')
        .toList();
  }

  /// Get students on bus - O(n) where n is students on bus
  List<Student> getStudentsOnBus(String busId) {
    final bus = buses[busId];
    if (bus == null) return [];

    return bus.onBoardStudents
        .map((id) => students[id])
        .whereType<Student>()
        .toList();
  }

  // === GENERAL OPERATIONS ===

  /// Clear all data
  void clear() {
    students.clear();
    drivers.clear();
    buses.clear();
    emailToStudentId.clear();
    emailToDriverId.clear();
    driverToBuses.clear();
  }

  /// Get total counts
  Map<String, int> getCounts() => {
    'students': students.length,
    'drivers': drivers.length,
    'buses': buses.length,
  };

  /// Search entities by query
  Map<String, dynamic> search(String query) {
    final lowerQuery = query.toLowerCase();

    return {
      'students': students.values
          .where((s) =>
              s.name.toLowerCase().contains(lowerQuery) ||
              s.email.toLowerCase().contains(lowerQuery))
          .toList(),
      'drivers': drivers.values
          .where((d) =>
              d.name.toLowerCase().contains(lowerQuery) ||
              d.email.toLowerCase().contains(lowerQuery))
          .toList(),
      'buses': buses.values
          .where((b) =>
              b.routeName.toLowerCase().contains(lowerQuery) ||
              b.registrationNumber.toLowerCase().contains(lowerQuery))
          .toList(),
    };
  }
}
