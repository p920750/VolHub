import 'package:flutter/material.dart';

class IdVerificationScreen extends StatelessWidget {
  const IdVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ID Verification')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, size: 80, color: Colors.indigo),
              const SizedBox(height: 24),
              Text(
                'Verify Your Identity',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'To build trust in the community, we need to verify your identity. Please upload a government-issued ID.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to upload front of ID'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/manager-dashboard'), // Redirect to dashboard for demo
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: const Text('Submit & Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/manager-dashboard'),
                child: const Text('Skip for now (Demo)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
