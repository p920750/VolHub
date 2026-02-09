import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Data matching the screenshot
    final stats = [
      {
        'title': 'Active Teams',
        'count': '2',
        'icon': FontAwesomeIcons.peopleGroup,
        'bgColor': AppColors.hunterGreen,
        'textColor': Colors.white,
        'subTextColor': Colors.white,
        'hasGraph': false,
      },
      {
        'title': 'Total Members',
        'count': '3',
        'icon': FontAwesomeIcons.userGroup, // Close enough to the icon in image
        'bgColor': AppColors.hunterGreen,
        'textColor': Colors.white,
        'subTextColor': Colors.white,
        'hasGraph': false,
      },
      {
        'title': 'Open Job Postings',
        'count': '1',
        'icon': FontAwesomeIcons.suitcase,
        'bgColor': AppColors.hunterGreen,
        'textColor': Colors.white,
        'subTextColor': Colors.white,
        'hasGraph': false,
      },
      {
        'title': 'Pending Applications',
        'count': '2',
        'icon': FontAwesomeIcons.paperPlane,
        'bgColor': AppColors.hunterGreen,
        'textColor': Colors.white,
        'subTextColor': Colors.white,
        'hasGraph': false,
      },
      {
        'title': 'Accepted Proposals',
        'count': '1',
        'icon': FontAwesomeIcons.dollarSign,
        'bgColor': AppColors.hunterGreen,
        'textColor': Colors.white,
        'subTextColor': Colors.white,
        'hasGraph': false,
      },
      {
        'title': 'Pending Proposals',
        'count': '1',
        'icon': FontAwesomeIcons.chartLine,
        'bgColor': AppColors.hunterGreen,
        'textColor': Colors.white,
        'subTextColor': Colors.white.withOpacity(0.9),
        'hasGraph': true, // Feature flag for graph
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columns as per screenshot
        childAspectRatio: 1.1, // Provide even more vertical space to eliminate the 9.3px overflow
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final item = stats[index];
        return StatCard(
          title: item['title'] as String,
          count: item['count'] as String,
          icon: item['icon'] as IconData,
          bgColor: item['bgColor'] as Color,
          textColor: item['textColor'] as Color,
          subTextColor: item['subTextColor'] as Color,
          hasGraph: item['hasGraph'] as bool,
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final Color subTextColor;
  final bool hasGraph;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.subTextColor,
    this.hasGraph = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subTextColor,
                            fontSize: 12,
                          ),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!hasGraph) // If graph exists, icon might be arguably redundant or placed differently, but in screenshot icon is there
                    Icon(
                      icon,
                      color: Colors.white70,
                      size: 20,
                    ),
                  if (hasGraph)
                     Icon(
                      icon,
                      color: Colors.white70,
                      size: 20,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                count,
                style: Theme.of(context).textTheme.titleLarge?.copyWith( // Reduced from headlineMedium to titleLarge
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
              ),
            ],
          ),
          if (hasGraph)
            Positioned(
              right: 0,
              bottom: 10,
              top: 20,
              width: 60,
              child: CustomPaint(
                painter: SparklinePainter(),
              ),
            ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Simple zig-zag pattern to mimic the screenshot
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.7);
    path.lineTo(size.width, size.height * 0.2); // trend up

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
