import 'package:flutter/material.dart';

class JobPostingCard extends StatelessWidget {
  final Map<String, dynamic> posting;
  final VoidCallback onTap;

  const JobPostingCard({super.key, required this.posting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF011638), // AppColors.midnightBlue
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.primaryContainer,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       'Open',
                       style: TextStyle(
                         fontSize: 10,
                         fontWeight: FontWeight.bold,
                         color: const Color(0xFF1B432C), // AppColors.hunterGreen
                       ),
                     ),
                   ),
                  Text(
                    'Posted 2 days ago',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                posting['title'],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                posting['description'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: (posting['skills'] as List<String>).map((skill) => 
                  Chip(
                    label: Text(skill, style: const TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  )
                ).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 20, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${posting['applications_count']} Applications',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDFF8EB), // AppColors.mintIce
                        ),
                      ),
                    ],
                  ),
                  FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDFF8EB), // AppColors.mintIce
                      foregroundColor: const Color(0xFF011638), // AppColors.midnightBlue
                    ),
                    child: const Text('Manage'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
