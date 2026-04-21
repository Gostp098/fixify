// lib/views/client/my_bookings_page.dart
// Zero Firebase imports — all logic lives in BookingProvider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/service_request_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Status grouping
// ─────────────────────────────────────────────────────────────────────────────
// Line ~14-17: change const → final
final _activeStatuses = {
  RequestStatus.pending,
  RequestStatus.accepted,
  RequestStatus.inProgress,
};

final _pastStatuses = {
  RequestStatus.completed,
  RequestStatus.cancelled,
};

List<ServiceRequest> _active(List<ServiceRequest> all) =>
    all.where((b) => _activeStatuses.contains(b.status)).toList();

List<ServiceRequest> _past(List<ServiceRequest> all) =>
    all.where((b) => _pastStatuses.contains(b.status)).toList();

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().listenToClientBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1A1A1A),
              unselectedLabelColor: const Color(0xFF9E9E9E),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
              indicatorColor: const Color(0xFF2563EB),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.5,
              tabs: const [Tab(text: 'Active'), Tab(text: 'Past')],
            ),
          ),
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.loadState == BookingLoadState.loading) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (provider.loadState == BookingLoadState.error) {
            return _ErrorView(
              message: provider.errorMessage,
              onRetry: () => provider.listenToClientBookings(),
            );
          }

          final all = provider.clientBookings;

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingList(
                bookings: _active(all),
                emptyLabel: 'No active bookings',
                emptySubLabel: 'Book a service to get started',
                emptyIcon: Icons.event_available_outlined,
              ),
              _BookingList(
                bookings: _past(all),
                emptyLabel: 'No past bookings',
                emptySubLabel: 'Your completed bookings will appear here',
                emptyIcon: Icons.history_outlined,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List
// ─────────────────────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<ServiceRequest> bookings;
  final String emptyLabel;
  final String emptySubLabel;
  final IconData emptyIcon;

  const _BookingList({
    required this.bookings,
    required this.emptyLabel,
    required this.emptySubLabel,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 14),
            Text(emptyLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF424242))),
            const SizedBox(height: 6),
            Text(emptySubLabel,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF9E9E9E))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: bookings.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: BookingCard(booking: bookings[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking Card
// ─────────────────────────────────────────────────────────────────────────────

class BookingCard extends StatelessWidget {
  final ServiceRequest booking;
  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isActive = _activeStatuses.contains(booking.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured top strip
          _StatusBar(status: booking.status),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: category name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        booking.category.label,       // uses new extension
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: booking.status),
                  ],
                ),

                const SizedBox(height: 10),

                // Date
                _MetaRow(
                  icon: Icons.calendar_today_outlined,
                  text: booking.formattedDate,
                ),
                const SizedBox(height: 5),

                // Time slot
                _MetaRow(
                  icon: Icons.access_time_outlined,
                  text: booking.timeSlot.label,       // uses new extension
                ),
                const SizedBox(height: 5),

                // Address
                _MetaRow(
                  icon: Icons.location_on_outlined,
                  text: booking.address.isNotEmpty
                      ? booking.address
                      : 'No address provided',
                ),

                // Urgency pill
                if (booking.urgency == UrgencyLevel.urgent) ...[
                  const SizedBox(height: 10),
                  const _UrgencyPill(),
                ],

                // Action buttons — only for active bookings
                if (isActive) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  _ActionRow(booking: booking),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coloured top strip — different colour per status
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final RequestStatus status;
  const _StatusBar({required this.status});

  Color get _color => switch (status) {
        RequestStatus.pending    => const Color(0xFFFBBF24),
        RequestStatus.accepted   => const Color(0xFF60A5FA),
        RequestStatus.inProgress => const Color(0xFF6366F1),
        RequestStatus.completed  => const Color(0xFF10B981),
        RequestStatus.cancelled  => const Color(0xFFD1D5DB),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action row — buttons change per status
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final ServiceRequest booking;
  const _ActionRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final isActing = provider.isActing;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Cancel — while pending or accepted
            if (booking.status == RequestStatus.pending ||
                booking.status == RequestStatus.accepted)
              _ActionButton(
                label: 'Cancel',
                textColor: const Color(0xFFDC2626),
                borderColor: const Color(0xFFFECACA),
                isLoading: isActing,
                onPressed: () => _confirmCancel(context, provider),
              ),

            // Track — once accepted or in progress
            if (booking.status == RequestStatus.accepted ||
                booking.status == RequestStatus.inProgress) ...[
              const SizedBox(width: 8),
              _ActionButton(
                label: booking.status == RequestStatus.inProgress
                    ? 'Track live'
                    : 'Track',
                textColor: const Color(0xFF2563EB),
                borderColor: const Color(0xFFBFDBFE),
                filled: booking.status == RequestStatus.inProgress,
                onPressed: () {
                  // TODO: Navigator.push(context, MaterialPageRoute(
                  //   builder: (_) => TrackingScreen(requestId: booking.id!),
                  // ));
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, BookingProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel booking?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This action cannot be undone. The technician will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel',
                style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.cancelBooking(booking.id!);
      if (context.mounted) provider.resetActionState();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final RequestStatus status;
  const StatusBadge({super.key, required this.status});

  ({String label, Color bg, Color fg}) get _style => switch (status) {
        RequestStatus.pending    => (label: 'Pending',     bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E)),
        RequestStatus.accepted   => (label: 'Accepted',    bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1E40AF)),
        RequestStatus.inProgress => (label: 'In Progress', bg: const Color(0xFFE0E7FF), fg: const Color(0xFF3730A3)),
        RequestStatus.completed  => (label: 'Completed',   bg: const Color(0xFFD1FAE5), fg: const Color(0xFF065F46)),
        RequestStatus.cancelled  => (label: 'Cancelled',   bg: const Color(0xFFF3F4F6), fg: const Color(0xFF6B7280)),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(s.label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: s.fg)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta Row
// ─────────────────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF616161)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Urgency Pill
// ─────────────────────────────────────────────────────────────────────────────

class _UrgencyPill extends StatelessWidget {
  const _UrgencyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.bolt, size: 12, color: Color(0xFFDC2626)),
          SizedBox(width: 3),
          Text('Urgent',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color borderColor;
  final bool filled;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.textColor,
    required this.borderColor,
    this.filled = false,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: filled ? Colors.white : textColor,
          backgroundColor: filled ? textColor : Colors.transparent,
          side: BorderSide(color: filled ? textColor : borderColor),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: filled ? Colors.white : textColor),
              )
            : Text(label),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 52, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 16),
            const Text('Something went wrong',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF424242))),
            const SizedBox(height: 6),
            Text(
              message.isNotEmpty
                  ? message
                  : 'Could not load your bookings.',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}