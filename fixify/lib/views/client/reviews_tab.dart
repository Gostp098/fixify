// lib/views/client/reviews_tab.dart
// Zero Firebase imports — all logic lives in ReviewProvider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/review_provider.dart';
import '../../models/service_request_model.dart';
import '../../models/review_model.dart';

class ReviewsTab extends StatefulWidget {
  const ReviewsTab({super.key});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().listenToClientReviews();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border:
                Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1A1A1A),
            unselectedLabelColor: const Color(0xFF9E9E9E),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            indicatorColor: const Color(0xFF2563EB),
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(text: 'To Review'),
              Tab(text: 'Submitted'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: Consumer<ReviewProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2));
              }

              if (provider.loadState == ReviewLoadState.error) {
                return _ErrorView(
                  message: provider.errorMessage,
                  onRetry: () =>
                      provider.listenToClientReviews(),
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  // Pending reviews
                  _PendingList(
                      bookings: provider.pendingReviews),
                  // Submitted reviews
                  _SubmittedList(reviews: provider.myReviews),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending (to review) list
// ─────────────────────────────────────────────────────────────────────────────

class _PendingList extends StatelessWidget {
  final List<ServiceRequest> bookings;
  const _PendingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const _EmptyState(
        icon: Icons.rate_review_outlined,
        label: 'Nothing to review',
        subLabel: 'Completed bookings will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: bookings.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _PendingReviewCard(booking: bookings[i]),
      ),
    );
  }
}

class _PendingReviewCard extends StatelessWidget {
  final ServiceRequest booking;
  const _PendingReviewCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_outlined,
                color: Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.category.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text(booking.formattedDate,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),

          // Rate button
          TextButton(
            onPressed: () => _openRatingSheet(context, booking),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Rate'),
          ),
        ],
      ),
    );
  }

  void _openRatingSheet(BuildContext context, ServiceRequest booking) {
    if (booking.technicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No technician assigned to this booking.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(booking: booking),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submitted reviews list
// ─────────────────────────────────────────────────────────────────────────────

class _SubmittedList extends StatelessWidget {
  final List<Review> reviews;
  const _SubmittedList({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const _EmptyState(
        icon: Icons.star_outline_rounded,
        label: 'No reviews yet',
        subLabel: 'Your submitted reviews will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: reviews.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _SubmittedReviewCard(review: reviews[i]),
      ),
    );
  }
}

class _SubmittedReviewCard extends StatelessWidget {
  final Review review;
  const _SubmittedReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Star row + date
          Row(
            children: [
              StarDisplay(rating: review.rating),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),

          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF424242), height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSheet extends StatefulWidget {
  final ServiceRequest booking;
  const _RatingSheet({required this.booking});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Rate ${widget.booking.category.label}',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF1A1A1A)),
          ),
          Text(
            widget.booking.formattedDate,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 24),

          // Star picker
          const Text('Rating',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF424242))),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 36,
                    color: i < _rating
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Comment
          const Text('Comment',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF424242))),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              hintStyle:
                  const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF7F7F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
              counterStyle:
                  const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            ),
          ),
          const SizedBox(height: 20),

          // Submit button
          Consumer<ReviewProvider>(
            builder: (context, provider, _) {
              // Auto-close on success
              if (provider.submitState == ReviewSubmitState.success) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pop(context);
                    provider.resetSubmitState();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review submitted!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                });
              }

              return SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _rating == 0 || provider.isSubmitting
                      ? null
                      : () => _submit(provider),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFFBFDBFE),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: provider.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Review'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _submit(ReviewProvider provider) {
    provider.submitReview(
      technicianId: widget.booking.technicianId!,
      requestId: widget.booking.id!,
      rating: _rating,
      comment: _commentController.text,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Technician reviews screen
// ─────────────────────────────────────────────────────────────────────────────

class TechnicianReviewsScreen extends StatefulWidget {
  final String technicianId;
  const TechnicianReviewsScreen({super.key, required this.technicianId});

  @override
  State<TechnicianReviewsScreen> createState() =>
      _TechnicianReviewsScreenState();
}

class _TechnicianReviewsScreenState extends State<TechnicianReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ReviewProvider>()
          .listenToTechnicianReviews(widget.technicianId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Reviews',
            style:
                TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (provider.loadState == ReviewLoadState.error) {
            return _ErrorView(
              message: provider.errorMessage,
              onRetry: () => provider
                  .listenToTechnicianReviews(widget.technicianId),
            );
          }

          final reviews = provider.technicianReviews;

          return CustomScrollView(
            slivers: [
              // Average rating header
              SliverToBoxAdapter(
                child: _RatingSummary(
                  average: provider.averageRating,
                  count: reviews.length,
                ),
              ),

              // Reviews list
              if (reviews.isEmpty)
                const SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.star_outline_rounded,
                    label: 'No reviews yet',
                    subLabel: 'Reviews from clients will appear here',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TechReviewCard(review: reviews[i]),
                      ),
                      childCount: reviews.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double average;
  final int count;
  const _RatingSummary({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Text(
            average > 0 ? average.toStringAsFixed(1) : '—',
            style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1),
          ),
          const SizedBox(height: 8),
          StarDisplay(rating: average.round()),
          const SizedBox(height: 6),
          Text(
            '$count ${count == 1 ? 'review' : 'reviews'}',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}

class _TechReviewCard extends StatelessWidget {
  final Review review;
  const _TechReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarDisplay(rating: review.rating),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF424242),
                  height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class StarDisplay extends StatelessWidget {
  final int rating;
  const StarDisplay({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 18,
          color: i < rating
              ? const Color(0xFFFBBF24)
              : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  const _EmptyState(
      {required this.icon, required this.label, required this.subLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF424242))),
          const SizedBox(height: 6),
          Text(subLabel,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}

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
              message.isNotEmpty ? message : 'Could not load reviews.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E)),
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
