import 'package:flutter/material.dart';
import 'package:main_volhub/widgets/safe_avatar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:main_volhub/dashboards/managers/core/theme.dart';
import 'package:main_volhub/dashboards/managers/messages/group_info_screen.dart';
import 'package:main_volhub/dashboards/managers/messages/chat_detail_screen.dart';

import 'package:main_volhub/services/event_manager_service.dart';

class YourTeamsWidget extends StatefulWidget {
  const YourTeamsWidget({super.key});

  @override
  State<YourTeamsWidget> createState() => _YourTeamsWidgetState();
}

class _YourTeamsWidgetState extends State<YourTeamsWidget> {
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_teams.isEmpty) {
      return const SizedBox.shrink(); // Hide if no teams
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Teams',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/manager-teams'), 
                child: const Text('View All', style: TextStyle(color: AppColors.midnightBlue)),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 360 ? constraints.maxWidth - 32 : 320.0;
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _teams.length > 5 ? 5 : _teams.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final team = _teams[index];
                  return Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.midnightBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team['name'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Active Team',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: const Row(
                             children: [
                               Icon(Icons.star, color: Colors.amber, size: 14),
                               SizedBox(width: 4),
                               Text(
                                 'New',
                                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                               ),
                             ],
                           ),
                        )
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: SafeAvatar(
                                radius: 14,
                                imageUrl: (team['avatars'] as List).isNotEmpty ? team['avatars'][0] : '',
                                name: 'Team',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${team['members']} Members',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupInfoScreen(
                                      chatId: team['event_id'] ?? team['id'],
                                      groupName: team['name'] as String,
                                    ),
                                  ),
                                ).then((_) => _loadTeams());
                              },
                              icon: const Icon(Icons.settings, color: AppColors.mintIce, size: 20),
                              tooltip: 'Manage Team',
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatDetailScreen(
                                      chatId: team['event_id'] ?? team['id'],
                                      chatName: team['name'] as String,
                                      isGroup: true,
                                      avatarUrl: (team['avatars'] as List).isNotEmpty ? team['avatars'][0] : null,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(FontAwesomeIcons.solidMessage, size: 14, color: AppColors.midnightBlue),
                              label: const Text('Chat', style: TextStyle(color: AppColors.midnightBlue, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mintIce,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
