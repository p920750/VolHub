import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/review_service.dart';
import '../../../services/supabase_service.dart';
import '../core/manager_drawer.dart';

class MyPerformancePage extends StatefulWidget {
  const MyPerformancePage({super.key});

  @override
  State<MyPerformancePage> createState() => _MyPerformancePageState();
}

class _MyPerformancePageState extends State<MyPerformancePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final managerId = SupabaseService.currentUser?.id;
      if (managerId != null) {
        final reviews = await ReviewService.getReviewsForManager(managerId);
        if (mounted) {
          setState(() {
            _reviews = reviews;
            if (reviews.isNotEmpty) {
              _averageRating = reviews.map((r) => (r['overall_rating'] as num).toDouble()).reduce((a, b) => a + b) / reviews.length;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Performance', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-performance'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 32),
                    const Text(
                      'All Reviews',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_reviews.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('No reviews yet. Keep up the good work!', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ..._reviews.map((review) => _buildReviewCard(review)).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E4D40), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E4D40).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Average Rating',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 40),
              const SizedBox(width: 12),
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Based on ${_reviews.length} reviews',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final organizer = review['organizer'] as Map<String, dynamic>?;
    final event = review['event'] as Map<String, dynamic>?;
    final date = DateTime.parse(review['created_at']);
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return _ReviewCard(review: review);
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final organizer = review['organizer'] as Map<String, dynamic>?;
    final event = review['event'] as Map<String, dynamic>?;
    final date = DateTime.parse(review['created_at']);
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: _isExpanded ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event?['name'] ?? event?['title'] ?? 'Unknown Event',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'by ${organizer?['full_name'] ?? 'Organizer'} • $formattedDate',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        review['overall_rating'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const Divider(height: 32),
              _buildRatingRow('Communication', review['communication_rating']),
              _buildRatingRow('Leadership', review['leadership_rating']),
              _buildRatingRow('Planning', review['planning_rating']),
              _buildRatingRow('Problem Solving', review['problem_solving_rating']),
              _buildRatingRow('Execution', review['execution_rating']),
              if (review['feedback'] != null && review['feedback'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Feedback:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  review['feedback'],
                  style: TextStyle(color: Colors.grey[800], height: 1.4),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    review['work_again'] == true ? Icons.check_circle : Icons.cancel,
                    color: review['work_again'] == true ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      review['work_again'] == true ? 'Organizer would work with you again' : 'Organizer would not work with you again',
                      style: TextStyle(
                        color: review['work_again'] == true ? Colors.green : Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Icon(Icons.keyboard_arrow_up, color: Colors.grey[400]),
              ),
            ] else ...[
               const SizedBox(height: 8),
               Center(
                 child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
               ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, dynamic rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < (rating as num).toDouble().floor() ? Icons.star : Icons.star_border,
                size: 14,
                color: Colors.amber,
              );
            }),
          ),
        ],
      ),
    );
  }
}
