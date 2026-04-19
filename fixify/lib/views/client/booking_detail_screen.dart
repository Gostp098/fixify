import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request_model.dart';
import '../../providers/booking_provider.dart';

class BookingDetailScreen extends StatelessWidget {
  final ServiceRequest request;
  const BookingDetailScreen({Key? key, required this.request})
      : super(key: key);

  static const _primaryBlue = Color(0xFF2E5BFF);

  @override
  Widget build(BuildContext context) {
    // Stream live updates for this specific booking
    return StreamBuilder<ServiceRequest?>(
      stream: context
          .read<BookingProvider>()
          .streamBooking(request.id!),
      initialData: request,
      builder: (context, snap) {
        final r = snap.data ?? request;
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Color(0xFF1A1A2E)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              r.categoryLabel,
              style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.bold),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _StatusBadge(status: r.status),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress stepper
                _ProgressStepper(status: r.status),
                const SizedBox(height: 24),

                // Details card
                _SectionCard(
                  title: 'Request details',
                  children: [
                    _DetailRow(
                        Icons.build_outlined, 'Service',
                        r.categoryLabel),
                    _DetailRow(
                        Icons.calendar_today_outlined, 'Date',
                        r.formattedDate),
                    _DetailRow(
                        Icons.access_time_outlined, 'Time slot',
                        r.timeSlotLabel),
                    _DetailRow(
                        Icons.location_on_outlined, 'Address',
                        r.address),
                    if (r.apartmentInstructions != null &&
                        r.apartmentInstructions!.isNotEmpty)
                      _DetailRow(
                          Icons.info_outline, 'Instructions',
                          r.apartmentInstructions!),
                    _DetailRow(Icons.priority_high_outlined,
                        'Urgency', r.urgencyLabel),
                  ],
                ),
                const SizedBox(height: 16),

                // Description card
                _SectionCard(
                  title: 'Description',
                  children: [
                    Text(
                      r.description,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.6),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Technician card — only when assigned
                if (r.technicianId != null) ...[
                  _SectionCard(
                    title: 'Assigned technician',
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                const Color(0xFFF97316)
                                    .withOpacity(0.1),
                            child: const Icon(Icons.person,
                                color: Color(0xFFF97316)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Technician assigned',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                Text(
                                  'Contact via your preferred method',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Cancel — only when pending
                if (r.status == RequestStatus.pending)
                  _CancelButton(requestId: r.id!),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Progress stepper ──────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final RequestStatus status;
  const _ProgressStepper({required this.status});

  static const _steps = [
    (RequestStatus.pending, 'Pending', Icons.hourglass_empty),
    (RequestStatus.accepted, 'Accepted', Icons.check_circle_outline),
    (RequestStatus.inProgress, 'In Progress', Icons.build_outlined),
    (RequestStatus.completed, 'Done', Icons.task_alt),
  ];

  int get _currentStep {
    switch (status) {
      case RequestStatus.pending:    return 0;
      case RequestStatus.accepted:   return 1;
      case RequestStatus.inProgress: return 2;
      case RequestStatus.completed:  return 3;
      case RequestStatus.cancelled:  return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == RequestStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8D7DA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFF721C24)),
            SizedBox(width: 10),
            Text(
              'This booking was cancelled.',
              style: TextStyle(
                  color: Color(0xFF721C24),
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final current = _currentStep;
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Booking progress',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final stepIndex = i ~/ 2;
                final filled = stepIndex < current;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: filled
                        ? const Color(0xFF2E5BFF)
                        : Colors.grey.shade200,
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              final done = stepIndex <= current;
              final active = stepIndex == current;
              final (_, label, icon) = _steps[stepIndex];
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? const Color(0xFF2E5BFF)
                          : Colors.grey.shade200,
                      border: active
                          ? Border.all(
                              color: const Color(0xFF2E5BFF),
                              width: 2)
                          : null,
                    ),
                    child: Icon(icon,
                        size: 18,
                        color:
                            done ? Colors.white : Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: done
                          ? const Color(0xFF2E5BFF)
                          : Colors.grey,
                      fontWeight: active
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section card ─────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Cancel button ─────────────────────────────────────────────

class _CancelButton extends StatelessWidget {
  final String requestId;
  const _CancelButton({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: provider.isActing
              ? null
              : () => _confirm(context, provider),
          icon: const Icon(Icons.cancel_outlined,
              color: Colors.red, size: 18),
          label: const Text('Cancel this booking',
              style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context, BookingProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel booking?'),
        content: const Text(
            'This cannot be undone. The request will be removed from the queue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep it',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.cancelBooking(requestId);
              if (context.mounted) Navigator.pop(context);
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
}

// ── Status badge (reused from my_bookings_screen) ─────────────

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
          borderRadius: BorderRadius.circular(20)),
      child: Text(cfg.$3,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cfg.$2)),
    );
  }

  (Color, Color, String) _config() {
    switch (status) {
      case RequestStatus.pending:
        return (const Color(0xFFFFF3CD), const Color(0xFF856404), 'Pending');
      case RequestStatus.accepted:
        return (const Color(0xFFCCE5FF), const Color(0xFF004085), 'Accepted');
      case RequestStatus.inProgress:
        return (const Color(0xFFD1ECF1), const Color(0xFF0C5460), 'In Progress');
      case RequestStatus.completed:
        return (const Color(0xFFD4EDDA), const Color(0xFF155724), 'Completed');
      case RequestStatus.cancelled:
        return (const Color(0xFFF8D7DA), const Color(0xFF721C24), 'Cancelled');
    }
  }
}
