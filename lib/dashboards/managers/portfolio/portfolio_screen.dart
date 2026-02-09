import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/manager_drawer.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'title': 'Summer Music Festival 2025',
      'role': 'Lead Photographer',
      'date': 'July 15, 2025',
      'images': ['https://picsum.photos/200/200?random=1', 'https://picsum.photos/200/200?random=2'],
      'certificate': true,
      'caption': 'Captured some amazing moments at the festival!',
    },
    {
      'title': 'City Marathon',
      'role': 'Course Marshal',
      'date': 'April 20, 2025',
      'images': ['https://picsum.photos/200/200?random=3'],
      'certificate': true,
      'caption': 'Proud to be part of this energetic event.',
    },
    {
      'title': 'Christmas Charity Drive',
      'role': 'Coordinator',
      'date': 'Dec 24, 2024',
      'images': [],
      'certificate': false,
      'caption': 'Bringing smiles to faces during the holidays.',
    },
  ];

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
                          onTap: () => _showCreatePostSheet(context),
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
          ..._posts.map((post) {
            final hasHeader = post['title'] != null && (post['title'] as String).isNotEmpty;
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
                    if (hasHeader) ...[
                      Text(
                        (post['title'] ?? '') as String,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('${post['role'] ?? 'Volunteer'} • ${post['date'] ?? 'Just now'}', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                    ] else ...[
                      Row(
                        children: [
                          ClipOval(
                            child: Image.network(
                              'https://i.pravatar.cc/150?img=12',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 40,
                                height: 40,
                                color: Colors.blue.withOpacity(0.1),
                                child: const Icon(Icons.person, color: Colors.blue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alex Johnson', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(post['date'] ?? 'Just now', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (post['caption'] != null && (post['caption'] as String).isNotEmpty) ...[
                      Text(post['caption'] as String, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 12),
                    ],
                    if (post['uploadedFile'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (post['uploadedFile'] ?? 'Selected file') as String,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (post['images'] != null && (post['images'] as List).isNotEmpty)
                      Builder(builder: (context) {
                        final images = post['images'] as List;
                        if (images.length == 1) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              images[0],
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        }
                        return SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, imgIndex) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                images[imgIndex],
                                width: 300,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    if (post['images'] != null && (post['images'] as List).isNotEmpty) const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (post['certificate'] == true)
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Certificate'),
                          ),
                        const SizedBox(width: 8),
                        TextButton(onPressed: () {}, child: const Text('View Details')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context, {FileType? initialPickType}) {
    String? selectedFileName;
    final captionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickFile(FileType type) async {
            final result = await FilePicker.platform.pickFiles(type: type);
            if (result != null) {
              setModalState(() {
                selectedFileName = result.files.single.name;
              });
            }
          }

          if (initialPickType != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              pickFile(initialPickType!);
            });
            initialPickType = null;
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Color(0xFF424242))),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(
                    hintText: 'What inspired you today?',
                    hintStyle: TextStyle(color: Color(0xFF757575)),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.black87),
                  maxLines: null,
                  autofocus: true,
                ),
                if (selectedFileName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedFileName!,
                            style: const TextStyle(fontSize: 12, color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setModalState(() => selectedFileName = null),
                          icon: const Icon(Icons.cancel, size: 16, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    IconButton(onPressed: () => pickFile(FileType.image), icon: const Icon(Icons.image, color: Colors.blue)),
                    IconButton(onPressed: () => pickFile(FileType.video), icon: const Icon(Icons.videocam, color: Colors.green)),
                    IconButton(onPressed: () => pickFile(FileType.any), icon: const Icon(Icons.description, color: Colors.orange)),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        if (captionController.text.isNotEmpty || selectedFileName != null) {
                          setState(() {
                            final isImage = selectedFileName != null &&
                                (selectedFileName!.toLowerCase().endsWith('.jpg') ||
                                    selectedFileName!.toLowerCase().endsWith('.jpeg') ||
                                    selectedFileName!.toLowerCase().endsWith('.png'));

                            _posts.insert(0, {
                              'title': '',
                              'role': '',
                              'date': 'Just now',
                              'images': isImage ? ['https://picsum.photos/800/600?random=${DateTime.now().millisecondsSinceEpoch}'] : [],
                              'certificate': false,
                              'caption': captionController.text,
                              'uploadedFile': isImage ? null : selectedFileName,
                            });
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Post published successfully!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Post'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostOption(BuildContext context, IconData icon, String label, Color color, FileType type) {
    return TextButton.icon(
      onPressed: () => _showCreatePostSheet(context, initialPickType: type),
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
    );
  }
}

