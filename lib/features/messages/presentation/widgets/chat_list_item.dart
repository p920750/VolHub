import 'package:flutter/material.dart';
import 'package:vol_hub/core/theme.dart';

class ChatListItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String? avatarUrl;
  final bool isGroup;
  final int? memberCount;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    this.avatarUrl,
    this.isGroup = false,
    this.memberCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.charcoalBlue,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null ? Icon(isGroup ? Icons.groups : Icons.person, color: Colors.white70) : null,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: unreadCount > 0 ? AppColors.mintIce : Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (isGroup && memberCount != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '$memberCount M.',
                style: const TextStyle(fontSize: 12, color: AppColors.mintIce, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: Text(
              lastMessage,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.white : Colors.white60,
                fontSize: 14,
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.mintIce,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: AppColors.midnightBlue, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
