import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/technician_profile_provider.dart';
import 'job_detail_screen.dart';

class IncomingJobsScreen extends StatefulWidget {
  const IncomingJobsScreen({Key? key}) : super(key: key);

  @override
  State<IncomingJobsScreen> createState() =>
      _IncomingJobsScreenState();
}

class _IncomingJobsScreenState extends State<IncomingJobsScreen> {
  static const _orange = Color(0xFFF97316);
  bool _listenerStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerStarted) {
      _listenerStarted = true;
      final trade =
          context.read<TechnicianProfileProvider>().profile?.trade ?? '';
      if (trade.isNotEmpty) {
        context.read<BookingProvider>().listenToIncomingJobs(trade);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final jobs = provider.incomingJobs;

        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: _orange));
        }

        if (jobs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_off_outlined,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No incoming jobs right now.\nMake sure you\'re online on the dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        height: 1.6),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, i) =>
              _IncomingJobCard(request: jobs[i], provider: provider),
        );
      },
    );
  }
}

// ── Incoming job card ─────────────────────────────────────────

class _IncomingJobCard extends StatelessWidget {
  final ServiceRequest request;
  final BookingProvider provider;
  const _IncomingJobCard(
      {required this.request, required this.provider});

  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            request: request,
            isIncoming: true,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _orange.withOpacity(
                  request.urgency == UrgencyLevel.urgent
                      ? 0.5
                      : 0.2)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.categoryLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A1A2E)),
                    ),
                  ),
                  if (request.urgency == UrgencyLevel.urgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Urgent',
                          style: TextStyle(
                              color: _orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('New',
                          style: TextStyle(
                              color: Color(0xFF856404),
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _infoRow(Icons.location_on_outlined, request.address),
              const SizedBox(height: 4),
              _infoRow(Icons.calendar_today_outlined,
                  '${request.formattedDate} · ${request.timeSlotLabel}'),
              const SizedBox(height: 4),
              _infoRow(
                Icons.description_outlined,
                request.description,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.isActing
                          ? null
                          : () async {
                              await provider
                                  .declineJob(request.id!);
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: provider.isActing
                          ? null
                          : () async {
                              await provider
                                  .acceptJob(request.id!);
                              if (!context.mounted) return;
                              if (provider.actionState ==
                                  BookingActionState.success) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Job accepted! It\'s now in My Jobs.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                provider.resetActionState();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        elevation: 0,
                      ),
                      child: provider.isActing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : const Text('Accept',
                              style:
                                  TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text,
      {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
