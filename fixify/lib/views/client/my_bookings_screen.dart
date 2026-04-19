import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request_model.dart';
import '../../providers/booking_provider.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _primaryBlue = Color(0xFF2E5BFF);

  final _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Active'),
    Tab(text: 'Completed'),
    Tab(text: 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().listenToClientBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ServiceRequest> _filter(
      List<ServiceRequest> all, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return all
            .where((r) =>
                r.status == RequestStatus.pending ||
                r.status == RequestStatus.accepted ||
                r.status == RequestStatus.inProgress)
            .toList();
      case 2:
        return all
            .where((r) => r.status == RequestStatus.completed)
            .toList();
      case 3:
        return all
            .where((r) => r.status == RequestStatus.cancelled)
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(
              color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryBlue,
          indicatorWeight: 2.5,
          tabs: _tabs,
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(
                    color: _primaryBlue));
          }

          return TabBarView(
            controller: _tabController,
            children: List.generate(4, (i) {
              final filtered = _filter(provider.clientBookings, i);
              if (filtered.isEmpty) {
                return _buildEmpty(i);
              }
              return _buildList(filtered, provider);
            }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/service_request'),
        backgroundColor: _primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New request',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildList(
      List<ServiceRequest> items, BookingProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) =>
          _BookingCard(request: items[i], provider: provider),
    );
  }

  Widget _buildEmpty(int tabIndex) {
    final messages = [
      'No bookings yet.\nTap the button below to request a service.',
      'No active bookings.',
      'No completed bookings yet.',
      'No cancelled bookings.',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              messages[tabIndex],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Booking card widget ───────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final ServiceRequest request;
  final BookingProvider provider;

  const _BookingCard(
      {required this.request, required this.provider});

  static const _primaryBlue = Color(0xFF2E5BFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BookingDetailScreen(request: request),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoryIcon(request.category),
                      color: _primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.categoryLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          request.formattedDate,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: request.status),
                ],
              ),
            ),
            // Address
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                    ),
                  ),
                  if (request.urgency == UrgencyLevel.urgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Urgent',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFF97316),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Cancel button — only for pending
            if (request.status == RequestStatus.pending) ...[
              const Divider(height: 1),
              TextButton(
                onPressed: provider.isActing
                    ? null
                    : () => _confirmCancel(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Cancel request',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel booking?'),
        content: const Text(
            'This request will be cancelled and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep it',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.cancelBooking(request.id!);
              if (provider.actionState ==
                  BookingActionState.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(provider.errorMessage),
                      backgroundColor: Colors.red),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking cancelled.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              provider.resetActionState();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(ServiceCategory cat) {
    const map = {
      ServiceCategory.plumbing:        Icons.plumbing,
      ServiceCategory.electrical:      Icons.electrical_services,
      ServiceCategory.cleaning:        Icons.cleaning_services,
      ServiceCategory.acRepair:        Icons.ac_unit,
      ServiceCategory.painting:        Icons.format_paint,
      ServiceCategory.carpentry:       Icons.carpenter,
      ServiceCategory.welding:         Icons.handyman,
      ServiceCategory.applianceRepair: Icons.kitchen,
      ServiceCategory.other:           Icons.miscellaneous_services,
    };
    return map[cat] ?? Icons.build;
  }
}

// ── Status badge ──────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _config();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cfg.$3,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cfg.$2),
      ),
    );
  }

  (Color, Color, String) _config() {
    switch (status) {
      case RequestStatus.pending:
        return (
          const Color(0xFFFFF3CD),
          const Color(0xFF856404),
          'Pending'
        );
      case RequestStatus.accepted:
        return (
          const Color(0xFFCCE5FF),
          const Color(0xFF004085),
          'Accepted'
        );
      case RequestStatus.inProgress:
        return (
          const Color(0xFFD1ECF1),
          const Color(0xFF0C5460),
          'In Progress'
        );
      case RequestStatus.completed:
        return (
          const Color(0xFFD4EDDA),
          const Color(0xFF155724),
          'Completed'
        );
      case RequestStatus.cancelled:
        return (
          const Color(0xFFF8D7DA),
          const Color(0xFF721C24),
          'Cancelled'
        );
    }
  }
}
