import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/proposal_card.dart';
import '../core/manager_drawer.dart';
import '../../../services/event_manager_service.dart';

class ProposalsScreen extends ConsumerStatefulWidget {
  const ProposalsScreen({super.key});

  @override
  ConsumerState<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends ConsumerState<ProposalsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final applications = await EventManagerService.getAcceptedEvents();
      if (mounted) {
        setState(() {
          _applications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _applications.where((a) => a['status'] == 'pending').length.toString();
    final confirmedCount = _applications.where((a) => a['status'] == 'accepted').length.toString(); // Map 'accepted' to confirmed UI if needed
    final rejectedCount = _applications.where((a) => a['status'] == 'rejected').length.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Proposals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-proposals'),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildSummaryCard(context, 'Pending', pendingCount, Colors.orange),
                    const SizedBox(width: 16),
                    _buildSummaryCard(context, 'Accepted', confirmedCount, Colors.green),
                    const SizedBox(width: 16),
                    _buildSummaryCard(context, 'Rejected', rejectedCount, Colors.red),
                  ],
                ),
                const SizedBox(height: 24),
                _applications.isEmpty
                  ? const Center(child: Text('You haven\'t accepted any event requests yet.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        return ProposalCard(
                          application: _applications[index],
                          onReject: () {
                            _loadApplications(); // Refresh after rejection/withdrawal
                          },
                        );
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
