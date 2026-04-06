import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/manager_proposal_card.dart';
import '../core/manager_drawer.dart';
import '../../../services/event_manager_service.dart';
import '../../../services/supabase_service.dart';

class ProposalsScreen extends ConsumerStatefulWidget {
  const ProposalsScreen({super.key});

  @override
  ConsumerState<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends ConsumerState<ProposalsScreen> {
  List<Map<String, dynamic>> _eventRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventRequests();
  }

  Future<void> _loadEventRequests() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userData = await SupabaseService.getUserFromUsersTable();
      final List<String> categories = (userData?['company_category'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];

      final requests = await EventManagerService.getEventRequests(categories);
      if (mounted) {
        setState(() {
          _eventRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Event Proposals', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEventRequests,
          ),
        ],
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-proposals'),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _eventRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text(
                    'No new event requests found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                   const SizedBox(height: 8),
                   const Text(
                    'Check back later for new opportunities!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadEventRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _eventRequests.length,
                itemBuilder: (context, index) {
                  return ManagerProposalCard(
                    event: _eventRequests[index],
                    onStatusChanged: _loadEventRequests,
                  );
                },
              ),
            ),
    );
  }
}