import 'package:flutter/material.dart';
import 'package:vol_hub/features/recruit/presentation/widgets/applicants_list.dart';
import 'package:vol_hub/features/recruit/presentation/widgets/job_posting_card.dart';

class RecruitScreen extends StatefulWidget {
  const RecruitScreen({super.key});

  @override
  State<RecruitScreen> createState() => _RecruitScreenState();
}

class _RecruitScreenState extends State<RecruitScreen> {
  // Simple state to toggle view for demo
  String? selectedJobId;

  @override
  Widget build(BuildContext context) {
    if (selectedJobId != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Applications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => selectedJobId = null),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event Photographer Needed', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const ApplicantsList(),
            ],
          ),
        ),
      );
    }

    final jobs = [
      {
        'id': '1',
        'title': 'Event Photographer Needed',
        'description': 'Looking for an experienced photographer for a 2-day music festival.',
        'skills': ['Photography', 'Editing', 'High Energy'],
        'applications_count': 5
      },
      {
        'id': '2',
        'title': 'Security Volunteers',
        'description': 'Crowd control and safety for the main stage area.',
        'skills': ['Security', 'First Aid'],
        'applications_count': 12
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recruit'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return JobPostingCard(
            posting: job,
            onTap: () {
              setState(() {
                selectedJobId = job['id'] as String;
              });
            },
          );
        },
      ),
    );
  }
}
