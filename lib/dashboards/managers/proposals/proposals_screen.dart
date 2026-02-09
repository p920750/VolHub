import 'package:flutter/material.dart';
import 'widgets/proposal_card.dart';
import '../core/manager_drawer.dart';

class ProposalsScreen extends StatelessWidget {
  const ProposalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final proposals = [
      {'event': 'Tech Summit 2026', 'budget': '\$500', 'status': 'Accepted', 'date': '2 days ago', 'message': 'We can provide full photo/video coverage.'},
      {'event': 'Music Fest', 'budget': '\$1200', 'status': 'Pending', 'date': '3 days ago', 'message': 'Experienced team of 5 volunteers available.'},
      {'event': 'Local Marathon', 'budget': '\$300', 'status': 'Rejected', 'date': '1 week ago', 'message': 'Safety marshals needed?'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Proposals')),
      drawer: const ManagerDrawer(currentRoute: '/manager-proposals'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildSummaryCard(context, 'Pending', '4', Colors.orange),
                const SizedBox(width: 16),
                _buildSummaryCard(context, 'Accepted', '12', Colors.green),
                const SizedBox(width: 16),
                _buildSummaryCard(context, 'Rejected', '2', Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: proposals.length,
              itemBuilder: (context, index) {
                return ProposalCard(proposal: proposals[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
