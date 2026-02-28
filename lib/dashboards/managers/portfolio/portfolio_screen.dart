import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../core/manager_drawer.dart';
import '../../../services/event_manager_service.dart';
import '../../../services/supabase_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late Stream<List<Map<String, dynamic>>> _portfolioStream;

  @override
  void initState() {
    super.initState();
    _portfolioStream = EventManagerService.getPortfolioStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Portfolio')),
      drawer: const ManagerDrawer(currentRoute: '/manager-portfolio'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // LinkedIn/Facebook-style Create Post Section
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _showPortfolioForm(context),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Share your latest achievement...',
                              style: TextStyle(color: Color(0xFF616161)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPostOption(context, Icons.image, 'Photo', Colors.blue, FileType.image),
                      _buildPostOption(context, Icons.videocam, 'Video', Colors.green, FileType.video),
                      _buildPostOption(context, Icons.description, 'Certificate', Colors.orange, FileType.any),
                    ],
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _portfolioStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('No portfolio items yet. Share your first achievement!'),
                  ),
                );
              }

              return Column(
                children: items.map((post) {
                  final eventName = post['event_name'] ?? '';
                  final eventType = post['event_type'] ?? '';
                  final role = post['role_handled'] ?? '';
                  final outcome = post['outcome_summary'] ?? '';
                  final date = post['created_at'] != null 
                      ? DateTime.parse(post['created_at']).toLocal().toString().split(' ')[0] 
                      : 'Just now';
                  final photos = List<String>.from(post['photos'] ?? []);
                  final videos = List<String>.from(post['videos'] ?? []);
                  final allMedia = [...photos, ...videos];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(eventName.isNotEmpty ? eventName[0].toUpperCase() : 'E'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      eventName,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text('$eventType • $date', style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showPortfolioForm(context, item: post);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmationDialog(context, post['id']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(context, 'Role Handled', role),
                          if (outcome.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(context, 'Outcome', outcome),
                          ],
                          const SizedBox(height: 16),
                          if (allMedia.isNotEmpty)
                            SizedBox(
                              height: 200,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: allMedia.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final url = allMedia[index];
                                  final isVideo = url.toLowerCase().contains('.mp4') || 
                                                 url.toLowerCase().contains('.mov') ||
                                                 videos.contains(url);
                                  
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (isVideo)
                                          Container(
                                            width: 300,
                                            color: Colors.black87,
                                            child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
                                          )
                                        else
                                          Image.network(
                                            url,
                                            width: 300,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 300,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        if (isVideo)
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 10)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Portfolio Item'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await EventManagerService.deletePortfolioItem(id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting item: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPortfolioForm(BuildContext context, {FileType? initialPickType, Map<String, dynamic>? item}) {
    final bool isEditing = item != null;
    final eventNameController = TextEditingController(text: item?['event_name']);
    final eventTypeController = TextEditingController(text: item?['event_type']);
    final roleHandledController = TextEditingController(text: item?['role_handled']);
    final outcomeSummaryController = TextEditingController(text: item?['outcome_summary']);
    
    // For editing, we might have existing URLs
    final List<String> existingPhotos = isEditing ? List<String>.from(item['photos'] ?? []) : [];
    final List<String> existingVideos = isEditing ? List<String>.from(item['videos'] ?? []) : [];
    
    // New files being picked
    List<File> selectedFiles = [];
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickFiles(FileType type) async {
            final result = await FilePicker.platform.pickFiles(
              type: type,
              allowMultiple: true,
            );
            if (result != null) {
              setModalState(() {
                selectedFiles.addAll(result.paths.where((p) => p != null).map((p) => File(p!)));
              });
            }
          }

          if (initialPickType != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              pickFiles(initialPickType!);
            });
            initialPickType = null;
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Portfolio Item' : 'Add Portfolio Item',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      IconButton(
                        onPressed: isUploading ? null : () => Navigator.pop(context), 
                        icon: const Icon(Icons.close, color: Color(0xFF424242)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPostTextField(eventNameController, 'Event Name', Icons.event),
                  const SizedBox(height: 12),
                  _buildPostTextField(eventTypeController, 'Event Type (e.g. Wedding, Concert)', Icons.category),
                  const SizedBox(height: 12),
                  _buildPostTextField(roleHandledController, 'Role Handled', Icons.work),
                  const SizedBox(height: 12),
                  _buildPostTextField(outcomeSummaryController, 'Outcome Summary', Icons.summarize, maxLines: 3),
                  
                  const SizedBox(height: 20),
                  const Text('Media', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // Show existing media if editing
                  if (isEditing && (existingPhotos.isNotEmpty || existingVideos.isNotEmpty)) ...[
                    const Text('Existing Media', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: existingPhotos.length + existingVideos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isPhoto = index < existingPhotos.length;
                          final url = isPhoto ? existingPhotos[index] : existingVideos[index - existingPhotos.length];
                          
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: isPhoto 
                                  ? Image.network(url, width: 80, height: 80, fit: BoxFit.cover)
                                  : Container(
                                      width: 80, 
                                      height: 80, 
                                      color: Colors.black87, 
                                      child: const Icon(Icons.play_circle_outline, color: Colors.white),
                                    ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      if (isPhoto) {
                                        existingPhotos.removeAt(index);
                                      } else {
                                        existingVideos.removeAt(index - existingPhotos.length);
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (selectedFiles.isNotEmpty) ...[
                    const Text('New Media', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedFiles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final file = selectedFiles[index];
                          final isVideo = file.path.toLowerCase().endsWith('.mp4') || 
                                         file.path.toLowerCase().endsWith('.mov');
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                  image: !isVideo ? DecorationImage(
                                    image: FileImage(file),
                                    fit: BoxFit.cover,
                                  ) : null,
                                ),
                                child: isVideo ? const Icon(Icons.videocam, size: 40, color: Colors.grey) : null,
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setModalState(() => selectedFiles.removeAt(index)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: isUploading ? null : () => pickFiles(FileType.image),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Photos'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: isUploading ? null : () => pickFiles(FileType.video),
                        icon: const Icon(Icons.video_call),
                        label: const Text('Add Video'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isUploading ? null : () async {
                        if (eventNameController.text.isEmpty || 
                            eventTypeController.text.isEmpty || 
                            roleHandledController.text.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in required fields.')),
                          );
                          return;
                        }

                        setModalState(() => isUploading = true);

                        try {
                          final List<String> photoUrls = [...existingPhotos];
                          final List<String> videoUrls = [...existingVideos];

                          for (final file in selectedFiles) {
                            final url = await EventManagerService.uploadPortfolioMedia(file);
                            if (url != null) {
                              final isVideo = file.path.toLowerCase().endsWith('.mp4') || 
                                             file.path.toLowerCase().endsWith('.mov');
                              if (isVideo) {
                                videoUrls.add(url);
                              } else {
                                photoUrls.add(url);
                              }
                            }
                          }

                          if (isEditing) {
                            await EventManagerService.updatePortfolioItem(
                              id: item['id'],
                              eventName: eventNameController.text,
                              eventType: eventTypeController.text,
                              roleHandled: roleHandledController.text,
                              outcomeSummary: outcomeSummaryController.text,
                              photos: photoUrls,
                              videos: videoUrls,
                            );
                          } else {
                            await EventManagerService.addPortfolioItem(
                              eventName: eventNameController.text,
                              eventType: eventTypeController.text,
                              roleHandled: roleHandledController.text,
                              outcomeSummary: outcomeSummaryController.text,
                              photos: photoUrls,
                              videos: videoUrls,
                            );
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing ? 'Portfolio item updated successfully!' : 'Portfolio item added successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving portfolio item: $e')),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setModalState(() => isUploading = false);
                          }
                        }
                      },
                      child: isUploading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : Text(isEditing ? 'Update Portfolio' : 'Add to Portfolio'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildPostOption(BuildContext context, IconData icon, String label, Color color, FileType type) {
    return TextButton.icon(
      onPressed: () => _showPortfolioForm(context, initialPickType: type),
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
    );
  }
}

