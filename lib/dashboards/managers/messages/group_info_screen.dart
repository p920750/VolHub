import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:main_volhub/dashboards/managers/core/theme.dart';
import 'package:main_volhub/services/event_manager_service.dart';
import 'package:main_volhub/services/supabase_service.dart';
import 'package:main_volhub/dashboards/managers/messages/chat_detail_screen.dart';

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
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _currentUserRole = 'Volunteer';
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.groupName);
    _fetchMembers();
  }
  
  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await EventManagerService.getGroupMembers(widget.chatId);
      final currentUserId = SupabaseService.currentUser?.id;
      
      // Determine current user's role in this group and fetch existing image
      if (currentUserId != null) {
        final myMember = members.firstWhere((m) => m['id'] == currentUserId, orElse: () => {});
        if (myMember.isNotEmpty) {
          _currentUserRole = myMember['role'];
        }
      }

      // We need to get the event's current image_url
      final event = await SupabaseService.client
          .from('events')
          .select('image_url')
          .eq('id', widget.chatId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _members = members;
          _currentImageUrl = event?['image_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (_currentUserRole != 'Manager') return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleSave() async {
    if (_currentUserRole != 'Manager') {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? imageUrl = _currentImageUrl;
      
      if (_selectedImage != null) {
        imageUrl = await SupabaseService.uploadChatAttachment(
          file: _selectedImage!,
          chatId: widget.chatId,
        );
      }

      await EventManagerService.updateEventGroupInfo(
        eventId: widget.chatId,
        name: _nameController.text.trim(),
        imageUrl: imageUrl,
      );

      if (mounted) {
        Navigator.pop(context, _nameController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _removeMember(int index) async {
    final member = _members[index];
    if (member['role'] == 'Manager') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Managers cannot be removed from the group.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member['name']} from the team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      // Capture the messenger before the async call
      final messenger = ScaffoldMessenger.of(context);
      
      try {
        await EventManagerService.removeTeamMember(widget.chatId, member['id']);
        await _fetchMembers();
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('${member['name']} removed from team.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          messenger.showSnackBar(
            SnackBar(content: Text('Error removing member: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showAddMemberDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adding members manually is disabled for events.')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Group Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        actions: [
          if (_currentUserRole == 'Manager')
            _isSaving 
              ? const Center(child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AA8D))),
                ))
              : TextButton(
                  onPressed: _handleSave,
                  child: const Text('Save', style: TextStyle(color: Color(0xFF00AA8D), fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00AA8D).withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImage != null 
                            ? FileImage(_selectedImage!) 
                            : _currentImageUrl != null 
                                ? NetworkImage(_currentImageUrl!) as ImageProvider
                                : null,
                        child: (_selectedImage == null && _currentImageUrl == null)
                            ? Icon(Icons.group, size: 60, color: Colors.grey[400])
                            : null,
                      ),
                    ),
                    if (_currentUserRole == 'Manager')
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFF00AA8D), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GROUP NAME', style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 1.2)),
                    TextField(
                      controller: _nameController,
                      enabled: _currentUserRole == 'Manager',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Group Name',
                        hintStyle: TextStyle(color: Colors.grey[300]),
                        border: InputBorder.none,
                        suffixIcon: _currentUserRole == 'Manager' ? Icon(Icons.edit, color: Colors.grey[400], size: 16) : null,
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
                  Text('${_members.length} MEMBERS', style: TextStyle(color: Colors.grey[600], fontSize: 12, letterSpacing: 1.2)),
                  TextButton.icon(
                    onPressed: _showAddMemberDialog,
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF00AA8D)),
                    label: const Text('Add', style: TextStyle(color: Color(0xFF00AA8D))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.mintIce)) :
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = _members[index];
                final isMe = member['id'] == SupabaseService.currentUser?.id;
                
                // Volunteers can only chat with Managers. Managers can chat with anyone.
                final bool canChat = !isMe && (_currentUserRole == 'Manager' || member['role'] == 'Manager');

                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      backgroundImage: member['avatar'] != null && member['avatar'].toString().isNotEmpty
                          ? NetworkImage(member['avatar'])
                          : null,
                      child: member['avatar'] == null || member['avatar'].toString().isEmpty
                          ? Text(member['name'][0], style: const TextStyle(color: Color(0xFF00AA8D)))
                          : null,
                    ),
                    title: Text(isMe ? '${member['name']} (You)' : member['name'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                    subtitle: Text(member['role'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canChat)
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF00AA8D), size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    chatId: member['id'],
                                    chatName: member['name'],
                                    avatarUrl: member['avatar'],
                                    isGroup: false,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_currentUserRole == 'Manager' && !isMe)
                          IconButton(
                            icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
                            onPressed: () => _removeMember(index),
                          ),
                      ],
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
