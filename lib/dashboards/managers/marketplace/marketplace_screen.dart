import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/event_request_card.dart';
import '../core/manager_drawer.dart';
import '../../../services/event_manager_service.dart';
import '../profile/profile_provider.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventRequests();
  }

  Future<void> _loadEventRequests() async {
    setState(() => _isLoading = true);
    try {
      final profile = ref.read(userProfileProvider).value;
      final requests = await EventManagerService.getEventRequests(profile?.category);
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEventRequests,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-marketplace'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search skills, titles, or locations...',
              leading: const Icon(Icons.search),
              onChanged: (value) {},
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)),
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _requests.isEmpty
                ? const Center(child: Text('No new event requests found.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      return EventRequestCard(
                        request: _requests[index],
                        onAccept: () {
                          _loadEventRequests(); // Refresh to remove accepted item
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
