import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../services/supabase_service.dart';

class ManagerReviewPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> manager;

  const ManagerReviewPage({
    super.key,
    required this.event,
    required this.manager,
  });

  @override
  State<ManagerReviewPage> createState() => _ManagerReviewPageState();
}

class _ManagerReviewPageState extends State<ManagerReviewPage> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _workAgain = true;
  bool _isSubmitting = false;

  final Map<String, double> _ratings = {
    'Overall': 5.0,
    'Communication': 5.0,
    'Leadership': 5.0,
    'Planning': 5.0,
    'Problem Solving': 5.0,
    'Event Execution': 5.0,
  };

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    try {
      final organizerId = SupabaseService.currentUser?.id;
      if (organizerId == null) throw 'User not logged in';

      await ReviewService.submitReview(
        eventId: widget.event['id'].toString(),
        organizerId: organizerId,
        managerId: widget.manager['id'].toString(),
        overallRating: _ratings['Overall']!,
        communicationRating: _ratings['Communication']!,
        leadershipRating: _ratings['Leadership']!,
        planningRating: _ratings['Planning']!,
        problemSolvingRating: _ratings['Problem Solving']!,
        executionRating: _ratings['Event Execution']!,
        feedback: _feedbackController.text.trim(),
        workAgain: _workAgain,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Review Manager', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            ..._ratings.keys.map((category) => _buildRatingCategory(category)).toList(),
            const SizedBox(height: 32),
            const Text(
              'Feedback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience with this manager...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Would you work with this manager again?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildChoiceChip('Yes', true),
                const SizedBox(width: 12),
                _buildChoiceChip('No', false),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4D40),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E4D40).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: widget.manager['profile_photo'] != null ? NetworkImage(widget.manager['profile_photo']) : null,
            child: widget.manager['profile_photo'] == null ? const Icon(Icons.person, size: 30) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.manager['full_name'] ?? 'Alex Johnson',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Event: ${widget.event['title'] ?? "TechFest 2026"}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCategory(String category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _ratings[category] = index + 1.0;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        index < _ratings[category]! ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool value) {
    final bool isSelected = _workAgain == value;
    return GestureDetector(
      onTap: () => setState(() => _workAgain = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E4D40) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? const Color(0xFF1E4D40) : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
