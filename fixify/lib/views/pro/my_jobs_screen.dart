import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request_model.dart';
import '../../providers/booking_provider.dart';
import 'job_detail_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({Key? key}) : super(key: key);

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _listenerStarted = false;
  static const _orange = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerStarted) {
      _listenerStarted = true;
      context.read<BookingProvider>().listenToMyJobs();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ServiceRequest> _filter(
      List<ServiceRequest> all, int tab) {
    switch (tab) {
      case 0: // Active
        return all
            .where((r) =>
                r.status == RequestStatus.accepted ||
                r.status == RequestStatus.inProgress)
            .toList();
      case 1: // Completed
        return all
            .where((r) => r.status == RequestStatus.completed)
            .toList();
      default: // All
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
          'My Jobs',
          style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _orange,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: List.generate(3, (i) {
              final list = _filter(provider.myJobs, i);
              if (list.isEmpty) return _empty(i);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, idx) =>
                    _MyJobCard(request: list[idx]),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _empty(int tab) {
    final msgs = [
      'No active jobs.\nAccept a job from the Incoming Jobs tab.',
      'No completed jobs yet.',
      'No jobs yet.',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              msgs[tab],
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

// ── My job card ───────────────────────────────────────────────

class _MyJobCard extends StatelessWidget {
  final ServiceRequest request;
  const _MyJobCard({required this.request});

  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final isInProgress = request.status == RequestStatus.inProgress;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            request: request,
            isIncoming: false,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isInProgress
              ? Border.all(color: _orange.withOpacity(0.4))
              : null,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _icon(request.category),
                      color: _orange,
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
                              color: Color(0xFF1A1A2E)),
                        ),
                        Text(
                          '${request.formattedDate} · ${request.timeSlotLabel}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
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
                ],
              ),
              if (isInProgress) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_outlined,
                          size: 14, color: _orange),
                      SizedBox(width: 6),
                      Text('Tap to update status',
                          style: TextStyle(
                              fontSize: 12,
                              color: _orange,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(ServiceCategory cat) {
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

class _StatusChip extends StatelessWidget {
  final RequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: cfg.$1, borderRadius: BorderRadius.circular(20)),
      child: Text(cfg.$3,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cfg.$2)),
    );
  }

  (Color, Color, String) _cfg() {
    switch (status) {
      case RequestStatus.accepted:
        return (const Color(0xFFCCE5FF), const Color(0xFF004085), 'Accepted');
      case RequestStatus.inProgress:
        return (const Color(0xFFFFE8D6), const Color(0xFF7C3100), 'In Progress');
      case RequestStatus.completed:
        return (const Color(0xFFD4EDDA), const Color(0xFF155724), 'Completed');
      default:
        return (const Color(0xFFF1EFE8), const Color(0xFF5F5E5A), status.name);
    }
  }
}
