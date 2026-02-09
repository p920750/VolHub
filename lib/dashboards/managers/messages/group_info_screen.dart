import 'package:flutter/material.dart';
import '../core/theme.dart';

class GroupInfoScreen extends StatefulWidget {
  final String chatId;
  final String groupName;

  const GroupInfoScreen({
    super.key,
    required this.chatId,
    required this.groupName,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late TextEditingController _nameController;
  late List<Map<String, String>> _members;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.groupName);
    // Mock members list
    _members = [
      {'name': 'Alex (You)', 'role': 'Host', 'id': 'me'},
      {'name': 'Alice', 'role': 'Member', 'id': '1'},
      {'name': 'Bob', 'role': 'Member', 'id': '2'},
      {'name': 'Charlie', 'role': 'Member', 'id': '3'},
      {'name': 'David', 'role': 'Member', 'id': '4'},
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Member removed')),
    );
  }

  void _showAddMemberDialog() {
    final List<Map<String, String>> potentialMembers = [
      {'name': 'Emma Watson', 'role': 'Event Coordinator', 'id': '5'},
      {'name': 'John Doe', 'role': 'Volunteer', 'id': '6'},
      {'name': 'Sarah Smith', 'role': 'Marketing', 'id': '7'},
      {'name': 'Mike Brown', 'role': 'Security', 'id': '8'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.midnightBlue,
        title: const Text('Add Member', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: potentialMembers.length,
            itemBuilder: (context, index) {
              final user = potentialMembers[index];
              final isAlreadyMember = _members.any((m) => m['id'] == user['id']);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.charcoalBlue,
                  child: Text(user['name']![0], style: const TextStyle(color: AppColors.mintIce)),
                ),
                title: Text(user['name']!, style: const TextStyle(color: Colors.white)),
                subtitle: Text(user['role']!, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                trailing: isAlreadyMember
                    ? const Icon(Icons.check_circle, color: AppColors.mintIce)
                    : const Icon(Icons.add_circle_outline, color: Colors.white24),
                onTap: isAlreadyMember
                    ? null
                    : () {
                        setState(() {
                          _members.add(user);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${user['name']} added to group')),
                        );
                      },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.mintIce)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Group Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _nameController.text);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.mintIce, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.mintIce, width: 2),
                      boxShadow: [
                        BoxShadow(color: AppColors.mintIce.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: AppColors.charcoalBlue,
                      child: Icon(Icons.group, size: 60, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.mintIce, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: AppColors.midnightBlue, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.charcoalBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GROUP NAME', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Group Name',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_members.length} MEMBERS', style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
                  TextButton.icon(
                    onPressed: _showAddMemberDialog,
                    icon: const Icon(Icons.add, size: 16, color: AppColors.mintIce),
                    label: const Text('Add', style: TextStyle(color: AppColors.mintIce)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = _members[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.midnightBlue,
                      child: Text(member['name']![0], style: const TextStyle(color: AppColors.mintIce)),
                    ),
                    title: Text(member['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(member['role']!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    trailing: member['id'] == 'me'
                        ? const Text('HOST', style: TextStyle(color: AppColors.mintIce, fontSize: 10, fontWeight: FontWeight.bold))
                        : IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _removeMember(index),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
