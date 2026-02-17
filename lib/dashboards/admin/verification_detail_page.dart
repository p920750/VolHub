import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'admin_colors.dart';

class VerificationDetailPage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onStatusChanged;

  const VerificationDetailPage({
    super.key, 
    required this.profileData,
    required this.onStatusChanged,
  });

  @override
  State<VerificationDetailPage> createState() => _VerificationDetailPageState();
}

class _VerificationDetailPageState extends State<VerificationDetailPage> {
  bool _isProcessing = false;
  String? _docUrl;

  @override
  void initState() {
    super.initState();
    _docUrl = widget.profileData['aadhar_doc_url'];
  }

   Future<void> _updateStatus(String status) async {
    // Capture context-dependent services before async gap
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isProcessing = true);
    
    try {
      await SupabaseService.client
          .from('users')
          .update({
            'verification_status': status,
            'is_aadhar_verified': status == 'verified'
          })
          .eq('id', widget.profileData['id']);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('User marked as $status'),
            backgroundColor: status == 'verified' ? AdminColors.success : AdminColors.error,
          ),
        );
        widget.onStatusChanged(); // Refresh parent list
        navigator.pop(); // Go back
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profileData['full_name'] ?? 'Unknown User';
    final id = widget.profileData['id'];

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: Text(name, style: const TextStyle(color: Colors.white)),
        backgroundColor: AdminColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => _updateStatus('rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.error,
                  side: const BorderSide(color: AdminColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('REJECT'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _updateStatus('verified'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('APPROVE'),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Info
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Details', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildDetailRow('Full Name', name),
                  _buildDetailRow('User ID', id),
                  _buildDetailRow('Status', widget.profileData['verification_status']),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Document Viewer
            Container(
               padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Verification Document', style: Theme.of(context).textTheme.titleLarge),
                   const SizedBox(height: 16),
                   if (_docUrl != null)
                     _buildDocumentPreview(_docUrl!)
                   else
                      const Text('No document URL found.', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  Widget _buildDocumentPreview(String url) {
    // Simple check for extension to determine rendering
    final isPdf = url.toLowerCase().contains('.pdf');

    if (isPdf) {
      return Container(
        height: 300,
        color: Colors.grey[100],
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('PDF Document'),
            const SizedBox(height: 16), // Increased spacing
            ElevatedButton.icon(
              onPressed: () => _launchUrl(url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            alignment: Alignment.center,
             child: const CircularProgressIndicator(),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 150,
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: const Column(
             mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(height: 8),
              Text('Failed to load image'),
            ],
          ),
        ),
      ),
    );
  }
}
