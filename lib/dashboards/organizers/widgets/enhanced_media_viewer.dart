import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class EnhancedMediaViewer extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final String messageId;
  final VoidCallback? onReply;

  const EnhancedMediaViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    required this.messageId,
    this.onReply,
  });

  @override
  State<EnhancedMediaViewer> createState() => _EnhancedMediaViewerState();
}

class _EnhancedMediaViewerState extends State<EnhancedMediaViewer> {
  final PhotoViewController _photoViewController = PhotoViewController();
  bool _isDownloading = false;

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    _photoViewController.scale = (_photoViewController.scale ?? 1.0) * 1.5;
  }

  void _zoomOut() {
    _photoViewController.scale = (_photoViewController.scale ?? 1.0) / 1.5;
  }

  Future<void> _shareImage() async {
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/shared_image.png').writeAsBytes(response.bodyBytes);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Check out this image from VolHub!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing image: $e')),
        );
      }
    }
  }

  Future<void> _downloadImage() async {
    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      
      // On Android/iOS, we would typically save to gallery. 
      // For this implementation, we'll save to the downloads/documents directory.
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'VolHub_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Image Viewer
          Center(
            child: Hero(
              tag: widget.heroTag,
              child: PhotoView(
                controller: _photoViewController,
                imageProvider: NetworkImage(widget.imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4.0,
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ),

          // Top Elevation/Gradient for better visibility of back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Action Buttons (Right Side)
          Positioned(
            top: 40,
            right: 10,
            child: Row(
              children: [
                if (widget.onReply != null)
                  IconButton(
                    icon: const Icon(Icons.reply, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onReply!();
                    },
                    tooltip: 'Reply',
                  ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareImage,
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: _isDownloading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download, color: Colors.white),
                  onPressed: _isDownloading ? null : _downloadImage,
                  tooltip: 'Download',
                ),
              ],
            ),
          ),

          // Zoom Controls (Bottom Right)
          Positioned(
            bottom: 40,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.zoom_in, color: Colors.white),
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.zoom_out, color: Colors.white),
                  onPressed: _zoomOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
