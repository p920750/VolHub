import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:vol_hub/core/theme.dart';
import 'package:vol_hub/features/messages/presentation/group_info_screen.dart';

class YourTeamsWidget extends StatelessWidget {
  const YourTeamsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final teams = [
      {
        'id': '3', // Matches mock group ID
        'name': 'Professional Photography Team',
        'members': 14,
        'events': 8,
        'rating': 4.8,
        'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        'avatars': [
          'https://i.pravatar.cc/150?img=1',
          'https://i.pravatar.cc/150?img=2',
          'https://i.pravatar.cc/150?img=3',
        ]
      },
      {
        'id': '4',
        'name': 'Gourmet Catering Crew',
        'members': 22,
        'events': 12,
        'rating': 4.9,
        'image': 'https://images.unsplash.com/photo-1555244162-803834f70033?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        'avatars': [
          'https://i.pravatar.cc/150?img=4',
          'https://i.pravatar.cc/150?img=5',
        ]
      },
    ];

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
                onPressed: () {}, 
                child: const Text('View All', style: TextStyle(color: AppColors.midnightBlue)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220, // Increased height for better layout
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: teams.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final team = teams[index];
              return Container(
                width: 320,
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
                              Text(
                                'Photography', // Simplified category
                                style: const TextStyle(color: Colors.white, fontSize: 12),
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
                           child: Row(
                             children: [
                               const Icon(Icons.star, color: Colors.amber, size: 14),
                               const SizedBox(width: 4),
                               Text(
                                 team['rating'].toString(),
                                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                              width: 60,
                              height: 30,
                              child: Stack(
                                children: [
                                  for (var i = 0; i < (team['avatars'] as List).length && i < 3; i++)
                                    Positioned(
                                      left: i * 15.0,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.white,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundImage: NetworkImage((team['avatars'] as List)[i] as String),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${(team['members'] as int) - (team['avatars'] as List).length}',
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
                                      chatId: team['id'] as String,
                                      groupName: team['name'] as String,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.settings, color: AppColors.mintIce, size: 20),
                              tooltip: 'Manage Team',
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Mock navigation to chat
                                context.push('/chat/${team['id']}');
                              },
                              icon: const Icon(FontAwesomeIcons.solidMessage, size: 14, color: AppColors.midnightBlue),
                              label: const Text('Message', style: TextStyle(color: AppColors.midnightBlue, fontWeight: FontWeight.bold)),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          '${team['members']} Members',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                         Text(
                          '${team['events']} Events',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
