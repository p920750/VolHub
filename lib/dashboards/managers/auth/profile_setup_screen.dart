import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tell us about yourself', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('This helps us match you with the right volunteers and events.'),
            const SizedBox(height: 24),
            
            Text('Skills & Expertise', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('Event Planning', true),
                _buildChip('Photography', false),
                _buildChip('Marketing', true),
                _buildChip('Logistics', false),
                _buildChip('First Aid', false),
                _buildChip('Teaching', false),
              ],
            ),
            
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
             const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Organization Name',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/manager-dashboard'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Complete Setup'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {}, 
      checkmarkColor: Colors.white,
    );
  }
}
