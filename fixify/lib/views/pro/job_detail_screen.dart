import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request_model.dart';
import '../../providers/booking_provider.dart';

class JobDetailScreen extends StatelessWidget {
  final ServiceRequest request;
  final bool isIncoming; // true = show Accept/Decline, false = show status update
  const JobDetailScreen(
      {Key? key, required this.request, this.isIncoming = false})
      : super(key: key);

  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + urgency chips
                Row(
                  children: [
                    _StatusChip(status: r.status),
                    if (r.urgency == UrgencyLevel.urgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Urgent',
                            style: TextStyle(
                                color: _orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Job details card
                _card(
                  title: 'Job details',
                  child: Column(
                    children: [
                      _row(Icons.build_outlined, 'Category',
                          r.categoryLabel),
                      _row(Icons.calendar_today_outlined, 'Date',
                          r.formattedDate),
                      _row(Icons.access_time_outlined,
                          'Time slot', r.timeSlotLabel),
                      _row(Icons.location_on_outlined, 'Address',
                          r.address),
                      if (r.apartmentInstructions != null &&
                          r.apartmentInstructions!.isNotEmpty)
                        _row(Icons.info_outline, 'Instructions',
                            r.apartmentInstructions!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description card
                _card(
                  title: 'Client description',
                  child: Text(
                    r.description,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.6),
                  ),
                ),
                const SizedBox(height: 24),

                // Action area
                Consumer<BookingProvider>(
                  builder: (context, provider, _) {
                    if (isIncoming) {
                      return _IncomingActions(
                          request: r, provider: provider);
                    } else {
                      return _StatusActions(
                          request: r, provider: provider);
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card({required String title, required Widget child}) {
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
          child,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
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
                      fontSize: 13, color: Colors.grey))),
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

// ── Accept / Decline actions (incoming jobs) ──────────────────

class _IncomingActions extends StatelessWidget {
  final ServiceRequest request;
  final BookingProvider provider;
  const _IncomingActions(
      {required this.request, required this.provider});

  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: provider.isActing
                ? null
                : () async {
                    await provider.acceptJob(request.id!);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Job accepted! Check My Jobs.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    provider.resetActionState();
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Accept job',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: provider.isActing
                ? null
                : () async {
                    await provider.declineJob(request.id!);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Decline',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status update actions (my jobs) ──────────────────────────

class _StatusActions extends StatelessWidget {
  final ServiceRequest request;
  final BookingProvider provider;
  const _StatusActions(
      {required this.request, required this.provider});

  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    // Determine what the next action is
    if (request.status == RequestStatus.accepted) {
      return _actionButton(
        context,
        label: 'Start job',
        icon: Icons.play_arrow_rounded,
        color: _orange,
        nextStatus: RequestStatus.inProgress,
        confirmMessage:
            'Mark this job as In Progress? The client will be notified.',
      );
    }

    if (request.status == RequestStatus.inProgress) {
      return _actionButton(
        context,
        label: 'Mark as completed',
        icon: Icons.task_alt,
        color: Colors.green,
        nextStatus: RequestStatus.completed,
        confirmMessage:
            'Mark this job as Completed? The client will be asked to leave a review.',
      );
    }

    if (request.status == RequestStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFD4EDDA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.task_alt, color: Color(0xFF155724)),
            SizedBox(width: 10),
            Text(
              'Job completed. Well done!',
              style: TextStyle(
                  color: Color(0xFF155724),
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required RequestStatus nextStatus,
    required String confirmMessage,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: provider.isActing
            ? null
            : () => _confirm(context, confirmMessage, nextStatus),
        icon: Icon(icon, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  void _confirm(BuildContext context, String message,
      RequestStatus nextStatus) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm action'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.updateJobStatus(
                  request.id!, nextStatus);
              if (!context.mounted) return;
              if (provider.actionState ==
                  BookingActionState.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(provider.errorMessage),
                      backgroundColor: Colors.red),
                );
              }
              provider.resetActionState();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final RequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: cfg.$1, borderRadius: BorderRadius.circular(20)),
      child: Text(cfg.$3,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cfg.$2)),
    );
  }

  (Color, Color, String) _cfg() {
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
