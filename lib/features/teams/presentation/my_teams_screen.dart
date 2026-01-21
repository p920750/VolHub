import 'package:flutter/material.dart';
import 'package:vol_hub/features/teams/presentation/widgets/team_card.dart';

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  final List<Map<String, dynamic>> _teams = [
    {
      'id': '3',
      'name': 'Photography Team',
      'members': 14,
      'events': 8,
      'applications': 0,
      'avatars': [
        'https://i.pravatar.cc/150?img=1',
        'https://i.pravatar.cc/150?img=2',
        'https://i.pravatar.cc/150?img=3',
      ],
    },
    {
      'id': '4',
      'name': 'Logistics Crew',
      'members': 22,
      'events': 12,
      'applications': 6,
      'avatars': [
        'https://i.pravatar.cc/150?img=4',
        'https://i.pravatar.cc/150?img=5',
        'https://i.pravatar.cc/150?img=6',
      ],
    },
    {
      'id': '5',
      'name': 'Social Media Squad',
      'members': 5,
      'events': 3,
      'applications': 2,
      'avatars': [
        'https://i.pravatar.cc/150?img=7',
        'https://i.pravatar.cc/150?img=8',
      ],
    },
    {
      'id': '6',
      'name': 'Medical Support',
      'members': 8,
      'events': 5,
      'applications': 1,
      'avatars': [
        'https://i.pravatar.cc/150?img=10',
        'https://i.pravatar.cc/150?img=11',
        'https://i.pravatar.cc/150?img=12',
      ],
    },
  ];

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();
    final eventsController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'e.g. Media Production Team',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: eventsController,
              decoration: const InputDecoration(
                labelText: 'Initial Events Completed',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _teams.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameController.text,
                    'members': 1,
                    'events': int.tryParse(eventsController.text) ?? 0,
                    'applications': 0,
                    'avatars': ['https://i.pravatar.cc/150?u=${DateTime.now().millisecondsSinceEpoch}'],
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Team "${nameController.text}" created!')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _teams.length,
        itemBuilder: (context, index) {
          return TeamCard(team: _teams[index]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTeamDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Team'),
      ),
    );
  }
}
