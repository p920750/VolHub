import 'package:flutter/material.dart';
import 'package:main_volhub/dashboards/managers/teams/widgets/team_card.dart';
import 'package:main_volhub/dashboards/managers/core/manager_drawer.dart';
import 'package:main_volhub/services/event_manager_service.dart';


class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final teams = await EventManagerService.getTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDeleteTeam(Map<String, dynamic> team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${team['name']}"? This will also clear the group chat history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await EventManagerService.deleteTeam(team['id'], team['event_id']);
        _loadTeams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting team: $e')),
          );
        }
      }
    }
  }

  void _showCreateTeamDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teams are automatically created when you accept volunteers for an event.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeams,
          ),
        ],
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-teams'),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _teams.isEmpty
          ? const Center(child: Text('No teams formed yet.\nAccept volunteers for an event to create a team.', textAlign: TextAlign.center))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                return TeamCard(
                  team: _teams[index],
                  onDelete: () => _handleDeleteTeam(_teams[index]),
                  onRefresh: _loadTeams,
                );
              },
            ),
    );
  }
}
