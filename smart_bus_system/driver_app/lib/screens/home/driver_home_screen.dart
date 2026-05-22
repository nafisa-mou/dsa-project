import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';
import '../../theme/app_theme.dart';
import '../../backend/firebase/firebase_models.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const _RouteTab(),
    const _PickupsTab(),
    const _PassengersTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen for error messages
    ref.listen<RouteState>(routeProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(routeProvider.notifier).clearError();
      }
    });

    final routeState = ref.watch(routeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.airport_shuttle, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Bus Driver',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (routeState.isDriving && routeState.activeTrip != null)
                  Text(
                    'Route: ${routeState.activeTrip!.routeName}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  )
                else
                  const Text(
                    'Status: Idle',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          if (routeState.isDriving)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'LIVE BROADCASTING',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
        elevation: 2,
      ),
      body: routeState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Route',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.person_pin_outlined),
                if (routeState.assignedPickups.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${routeState.assignedPickups.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.person_pin),
            label: 'Pickups',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.groups_outlined),
                if (routeState.activeTrip?.studentsBoarded.isNotEmpty ?? false)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${routeState.activeTrip!.studentsBoarded.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.groups),
            label: 'Onboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _RouteTab extends ConsumerStatefulWidget {
  const _RouteTab();

  @override
  ConsumerState<_RouteTab> createState() => _RouteTabState();
}

class _RouteTabState extends ConsumerState<_RouteTab> {
  final List<String> _routes = [
    'Main Campus Express (Stops: Gate 1, Admin Bldg, Library, Science Hall)',
    'North Residence Shuttle (Stops: North Dorms, Central Cafeteria, Playground, Gate 2)',
    'Science Building Loop (Stops: Science Hall, CSE Bldg, Mechanical Lab, South Gate)',
  ];

  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _selectedRoute = _routes.first;
  }

  void _startSelectedTrip() async {
    if (_selectedRoute == null) return;
    
    // Parse route name and stops from selection
    final routeParts = _selectedRoute!.split(' (Stops: ');
    final routeName = routeParts[0];
    final stopsString = routeParts[1].replaceAll(')', '');
    final stopsList = stopsString.split(', ');

    final success = await ref.read(routeProvider.notifier).startTrip(routeName, stopsList);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip "$routeName" started successfully!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(routeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status Card
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: routeState.isDriving
                      ? [AppTheme.primaryColor, AppTheme.secondaryColor]
                      : [Colors.grey[700]!, Colors.grey[850]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeState.isDriving ? 'ACTIVE VIRTUAL TRIP' : 'TRANSIT VEHICLE READY',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    routeState.isDriving
                        ? routeState.activeTrip?.routeName ?? 'On Route'
                        : 'Currently Offline / Idle',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusMetric(
                        icon: Icons.gps_fixed,
                        label: 'GPS Coordinates',
                        value: '${routeState.currentLatitude.toStringAsFixed(4)}, ${routeState.currentLongitude.toStringAsFixed(4)}',
                      ),
                      _StatusMetric(
                        icon: Icons.people,
                        label: 'Onboard Count',
                        value: '${routeState.activeTrip?.studentsBoarded.length ?? 0} Students',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (!routeState.isDriving) ...[
            // Route Picker Form
            Text(
              'Select Dispatch Route',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRoute,
                  isExpanded: true,
                  items: _routes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRoute = val),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startSelectedTrip,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 24),
                  SizedBox(width: 8),
                  Text('START TRIP & SIMULATE GPS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ] else ...[
            // Active Trip Dashboard Controls
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.speed, color: AppTheme.secondaryColor, size: 32),
                          const SizedBox(height: 8),
                          const Text('Current Speed', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                          Text('35 km/h', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.navigation, color: AppTheme.successColor, size: 32),
                          const SizedBox(height: 8),
                          const Text('Heading Angle', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                          Text('45.0° NE', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Route stops timeline
            Text(
              'Trip Stop Sequence',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: routeState.activeTrip?.stopsSequence.length ?? 0,
              itemBuilder: (context, index) {
                final stop = routeState.activeTrip!.stopsSequence[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: index == 0 ? AppTheme.primaryColor : AppTheme.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (index < routeState.activeTrip!.stopsSequence.length - 1)
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Text(
                            'Estimated Stop-by Wait: 3 mins',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => ref.read(routeProvider.notifier).endTrip(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: const BorderSide(color: AppTheme.errorColor),
                foregroundColor: AppTheme.errorColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop, size: 24),
                  SizedBox(width: 8),
                  Text('TERMINATE TRIP / DISPATCH BUS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatusMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _PickupsTab extends ConsumerWidget {
  const _PickupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);

    if (!routeState.isDriving) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.airport_shuttle, size: 64, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 20),
              Text(
                'Vehicle is Offline',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please start a route in the Route tab to begin receiving and fulfilling passenger pickup requests.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    if (routeState.assignedPickups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal[55],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.successColor),
              ),
              const SizedBox(height: 20),
              Text(
                'All Clear!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'No pending student pickup requests are currently dispatched to your vehicle. Safe travels!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      itemCount: routeState.assignedPickups.length,
      itemBuilder: (context, index) {
        final pickup = routeState.assignedPickups[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.bottom(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLightColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickup.studentName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Phone: ${pickup.studentPhone}',
                              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pickup.status == 'accepted' 
                            ? AppTheme.successColor.withOpacity(0.15) 
                            : AppTheme.warningColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pickup.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: pickup.status == 'accepted' ? AppTheme.successColor : AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request GPS Location',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                          ),
                          Text(
                            '${pickup.pickupLatitude.toStringAsFixed(4)}, ${pickup.pickupLongitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (pickup.estimatedArrivalMinutes != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Dynamic ETA',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                          ),
                          Text(
                            '${pickup.estimatedArrivalMinutes!.toStringAsFixed(0)} mins',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(routeProvider.notifier).completePickup(pickup.id, pickup.studentId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${pickup.studentName} has been successfully boarded!'),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('CONFIRM BOARDED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PassengersTab extends ConsumerWidget {
  const _PassengersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);

    if (!routeState.isDriving || routeState.activeTrip == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 20),
              Text(
                'No Active Trip Running',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please start a route first to manage boarded passengers on the bus.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    final boardedStudents = routeState.activeTrip!.studentsBoarded;

    if (boardedStudents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.no_accounts_outlined, size: 64, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 20),
              Text(
                'No Passengers On Board',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Once you confirm passenger boardings, they will be tracked on this manifest.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Onboard Passenger Manifest',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text('${boardedStudents.length} Active'),
                backgroundColor: AppTheme.primaryLightColor,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
            itemCount: boardedStudents.length,
            itemBuilder: (context, index) {
              final studentId = boardedStudents[index];

              return Card(
                elevation: 1.5,
                margin: const EdgeInsets.bottom(10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                    child: const Icon(Icons.person, color: AppTheme.secondaryDarkColor),
                  ),
                  title: Text(
                    'Student: ID-${studentId.substring(0, 5)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Verification Status: Checked-in via NFC/Dynamic QR',
                    style: TextStyle(fontSize: 12, color: AppTheme.successColor),
                  ),
                  trailing: const Icon(Icons.check_circle, color: AppTheme.successColor),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.person, size: 54, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Loading Driver...',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Licensed Fleet Captain',
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          _ProfileDetailRow(
            icon: Icons.email_outlined,
            label: 'Registered Email',
            value: user?.email ?? 'N/A',
          ),
          _ProfileDetailRow(
            icon: Icons.badge_outlined,
            label: 'Driver UID',
            value: user?.id ?? 'N/A',
          ),
          _ProfileDetailRow(
            icon: Icons.assignment_ind_outlined,
            label: 'Fleet Designation',
            value: 'Specialized Shuttle Operator',
          ),
          _ProfileDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joined Date',
            value: user?.createdAt != null 
                ? '${user!.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}' 
                : 'N/A',
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Successfully signed out.'),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('SIGN OUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
