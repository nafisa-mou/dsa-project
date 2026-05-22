import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../providers/pickup_provider.dart';
import '../../theme/app_theme.dart';
import '../../backend/firebase/firebase_models.dart';
import '../../backend/dsa_algorithms/priority_queue_scheduler.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.user == null) {
      // Direct users back to Login if unauthenticated
      // This works dynamically inside our auth state routing
      return Container();
    }

    final List<Widget> screens = [
      const _TrackingTab(),
      const _PickupTab(),
      const _HistoryTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Bus'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(Icons.local_taxi), label: 'Pickup'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _TrackingTab extends ConsumerWidget {
  const _TrackingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingProvider);

    return Container(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        children: [
          // MAP PORT
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
                color: Colors.grey[300],
                boxShadow: const [AppTheme.defaultShadow],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 64, color: AppTheme.primaryColor.withOpacity(0.5)),
                        const SizedBox(height: AppTheme.mediumSpacing),
                        Text(
                          'Google Map View Enabled',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                        const SizedBox(height: AppTheme.smallSpacing),
                        Text(
                          trackingState.activeBuses.isEmpty
                              ? 'Waiting for active buses...'
                              : 'Tracking ${trackingState.activeBuses.length} buses live',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // MOCK MAP WIDGET MARKERS
                  if (trackingState.activeBuses.isNotEmpty)
                    ...trackingState.activeBuses.map((bus) {
                      return Positioned(
                        left: 80 + (bus.latitude * 10) % 200,
                        top: 150 + (bus.longitude * 15) % 250,
                        child: Tooltip(
                          message: 'Bus ID: ${bus.entityId}\nSpeed: ${bus.speed ?? 0} km/h',
                          child: const Icon(
                            Icons.directions_bus_filled,
                            color: AppTheme.primaryColor,
                            size: 32,
                          ),
                        ),
                      );
                    }).toList(),

                  // USER GPS MARKER
                  if (trackingState.currentPosition != null)
                    Positioned(
                      left: 140,
                      top: 200,
                      child: Tooltip(
                        message: 'My Location',
                        child: Icon(
                          Icons.my_location,
                          color: AppTheme.accentColor,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.mediumSpacing),

          // CONTROL PANEL
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Transit Monitor',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: trackingState.isTrackingUser,
                        onChanged: (val) {
                          if (val) {
                            ref.read(trackingProvider.notifier).startTrackingUser();
                          } else {
                            ref.read(trackingProvider.notifier).stopTrackingUser();
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    trackingState.isTrackingUser 
                        ? 'Streaming my GPS location to sync ETAs.' 
                        : 'GPS stream disabled (tap to enable).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(),
                  if (trackingState.activeBuses.isEmpty)
                    const Center(child: Text('No active buses running currently.'))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trackingState.activeBuses.length,
                      separatorBuilder: (ctx, idx) => const Divider(),
                      itemBuilder: (ctx, idx) {
                        final bus = trackingState.activeBuses[idx];
                        final eta = trackingState.busEtas[bus.entityId] ?? 0.0;
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primaryLightColor,
                            child: Icon(Icons.directions_bus, color: AppTheme.primaryColor),
                          ),
                          title: Text('Bus ID: ${bus.entityId}'),
                          subtitle: Text('Speed: ${bus.speed?.toStringAsFixed(1) ?? '0.0'} km/h | Heading: ${bus.heading?.toStringAsFixed(0) ?? 'N/A'}°'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${eta.toStringAsFixed(0)} min',
                              style: const TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupTab extends ConsumerStatefulWidget {
  const _PickupTab();

  @override
  ConsumerState<_PickupTab> createState() => _PickupTabState();
}

class _PickupTabState extends ConsumerState<_PickupTab> {
  PickupPriority _selectedPriority = PickupPriority.medium;
  final _latController = TextEditingController(text: '23.8103');
  final _lngController = TextEditingController(text: '90.4125');

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _requestPickup() async {
    final success = await ref.read(pickupProvider.notifier).createRequest(
      latitude: double.parse(_latController.text.trim()),
      longitude: double.parse(_lngController.text.trim()),
      priority: _selectedPriority,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup request submitted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupState = ref.watch(pickupProvider);

    if (pickupState.activeRequest != null) {
      final req = pickupState.activeRequest!;
      return Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
                child: Column(
                  children: [
                    const Icon(Icons.local_taxi, size: 64, color: AppTheme.primaryColor),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    Text(
                      'Active Pickup Request',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    const Divider(),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    _buildRequestDetailRow('Request ID', req.id),
                    _buildRequestDetailRow('Status', req.status.toUpperCase(), isStatus: true),
                    _buildRequestDetailRow('Lat/Lng', '${req.pickupLatitude}, ${req.pickupLongitude}'),
                    _buildRequestDetailRow(
                      'Request Time',
                      DateFormat('hh:mm a').format(req.requestTime),
                    ),
                    if (req.assignedBusId != null) ...[
                      _buildRequestDetailRow('Assigned Bus', req.assignedBusId!),
                      _buildRequestDetailRow(
                        'Est. Arrival',
                        '${req.estimatedArrivalMinutes?.toStringAsFixed(0) ?? 'N/A'} mins',
                        isArrival: true,
                      ),
                    ],
                    const SizedBox(height: AppTheme.largeSpacing),
                    if (pickupState.isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel Request'),
                        onPressed: () => ref.read(pickupProvider.notifier).cancelRequest(req.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Dynamic Pickup',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          const Text('Request a campus bus stop to coordinate dynamic routing pickups.'),
          const SizedBox(height: AppTheme.largeSpacing),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specify Pickup Coordinates',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Latitude'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.mediumSpacing),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Longitude'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  Text(
                    'Urgency Level (Dijkstra Prioritizer)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  DropdownButtonFormField<PickupPriority>(
                    value: _selectedPriority,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPriority = val);
                      }
                    },
                    items: PickupPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority.toString().split('.').last.toUpperCase()),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Priority Level'),
                  ),
                  const SizedBox(height: AppTheme.largeSpacing),

                  if (pickupState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _requestPickup,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Request Pickup Now'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetailRow(String label, String value, {bool isStatus = false, bool isArrival = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.smallSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isStatus
                  ? AppTheme.primaryColor
                  : (isArrival ? AppTheme.successColor : AppTheme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupState = ref.watch(pickupProvider);

    return Container(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Requests Log',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          Expanded(
            child: pickupState.requestHistory.isEmpty
                ? const Center(child: Text('No previous pickup logs found.'))
                : ListView.separated(
                    itemCount: pickupState.requestHistory.length,
                    separatorBuilder: (ctx, idx) => const Divider(),
                    itemBuilder: (ctx, idx) {
                      final req = pickupState.requestHistory[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: req.status == 'completed'
                              ? AppTheme.successColor.withOpacity(0.2)
                              : (req.status == 'cancelled' ? AppTheme.errorColor.withOpacity(0.2) : AppTheme.primaryLightColor),
                          child: Icon(
                            req.status == 'completed'
                                ? Icons.check
                                : (req.status == 'cancelled' ? Icons.close : Icons.local_taxi),
                            color: req.status == 'completed'
                                ? AppTheme.successColor
                                : (req.status == 'cancelled' ? AppTheme.errorColor : AppTheme.primaryColor),
                          ),
                        ),
                        title: Text('Pickup Location: ${req.pickupLatitude.toStringAsFixed(4)}, ${req.pickupLongitude.toStringAsFixed(4)}'),
                        subtitle: Text('Status: ${req.status.toUpperCase()} | ${DateFormat('MMM d, hh:mm a').format(req.requestTime)}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.user == null) return Container();

    final user = authState.user!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person, size: 54, color: Colors.white),
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          Text(
            user.name,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(user.email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppTheme.largeSpacing),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.defaultPadding),
              child: Column(
                children: [
                  _buildProfileRow(context, 'User ID', user.id),
                  const Divider(),
                  _buildProfileRow(context, 'Access Level', user.userType.toUpperCase()),
                  const Divider(),
                  _buildProfileRow(
                    context,
                    'Joined System',
                    DateFormat('MMM d, yyyy').format(user.createdAt),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.smallSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
