// lib/views/pro/technician_reviews_screen.dart
// Zero Firebase imports — all logic lives in ReviewProvider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/review_provider.dart';
import '../../models/review_model.dart';

class TechnicianReviewsScreen extends StatefulWidget {
  const TechnicianReviewsScreen({super.key});

  @override
  State<TechnicianReviewsScreen> createState() =>
      _TechnicianReviewsScreenState();
}

class _TechnicianReviewsScreenState
    extends State<TechnicianReviewsScreen> {
  static const _orange = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<ReviewProvider>().uid;
      if (uid != null) {
        context.read<ReviewProvider>().listenToTechnicianReviews(uid);
      }
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
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        title: const Text(
          'My Reviews',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF1A1A2E)),
        ),
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, _) {
          // ── Loading ────────────────────────────────────────
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _orange));
          }

          // ── Error ──────────────────────────────────────────
          if (provider.loadState == ReviewLoadState.error) {
            return _ErrorView(
              message: provider.errorMessage,
              onRetry: () {
                final uid = provider.uid;
                if (uid != null) {
                  provider.listenToTechnicianReviews(uid);
                }
              },
            );
          }

          final reviews = provider.technicianReviews;

          return CustomScrollView(
            slivers: [
              // ── Rating summary header ──────────────────────
              SliverToBoxAdapter(
                child: _RatingSummary(
                  average: provider.averageRating,
                  count: reviews.length,
                ),
              ),

              // ── Reviews list / empty state ─────────────────
              if (reviews.isEmpty)
                const SliverFillRemaining(
                  child: _EmptyState(),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReviewCard(review: reviews[i]),
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

// ─────────────────────────────────────────────────────────────────────────────
// Rating summary card
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSummary extends StatelessWidget {
  final double average;
  final int count;
  const _RatingSummary({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          // Big number
          Text(
            average > 0 ? average.toStringAsFixed(1) : '—',
            style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
                height: 1),
          ),
          const SizedBox(height: 10),

          // Stars
          StarRow(rating: average.round(), size: 28),
          const SizedBox(height: 8),

          // Count
          Text(
            '$count ${count == 1 ? 'review' : 'reviews'}',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF9E9E9E)),
          ),

          // Rating breakdown bars
          if (count > 0) ...[
            const SizedBox(height: 20),
            const Divider(indent: 24, endIndent: 24),
            const SizedBox(height: 16),
            // placeholder: could add per-star breakdown here
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual review card
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

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
          // Top row: stars + date
          Row(
            children: [
              StarRow(rating: review.rating, size: 18),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),

          // Comment
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF424242),
                  height: 1.5),
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
// Reusable star row
// ─────────────────────────────────────────────────────────────────────────────

class StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const StarRow({super.key, required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          size: size,
          color: i < rating
              ? const Color(0xFFFBBF24)
              : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded,
              size: 56, color: Colors.grey[300]),
          const SizedBox(height: 14),
          const Text('No reviews yet',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF424242))),
          const SizedBox(height: 6),
          const Text('Reviews from clients will appear here',
              style:
                  TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
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