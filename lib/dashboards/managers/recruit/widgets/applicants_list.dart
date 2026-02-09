import 'package:flutter/material.dart';

class ApplicantsList extends StatelessWidget {
  const ApplicantsList({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building ApplicantsList');
    // Using simple mock data
    final applicants = [
      {
        'name': 'Sarah Jenkins',
        'role': 'Event Photographer',
        'experience': '3 Years',
        'email': 'sarah.j@example.com',
        'skills': ['Photography', 'Lightroom']
      },
      {
        'name': 'David Chen',
        'role': 'Event Photographer',
        'experience': '1 Year',
        'email': 'd.chen@example.com',
        'skills': ['Photography']
      },
    ];

    if (applicants.isEmpty) {
      return const Center(child: Text('No applicants yet.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: applicants.length,
      itemBuilder: (context, index) {
        final applicant = applicants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Text((applicant['name'] as String)[0])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(applicant['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(applicant['email'] as String, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(applicant['experience'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Proposal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                          Text('2 hours ago', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'I have extensive experience in this field and would love to contribute to your success.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  children: (applicant['skills'] as List<String>).map((s) => 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s, style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      )),
                    )
                  ).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Accept Applicant'),
                            content: Text('Are you sure you want to accept ${applicant['name']}? They will be added to the Professional Photography Team.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${applicant['name']} has been accepted and moved to the Professional Photography Team!')),
                                  );
                                },
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
