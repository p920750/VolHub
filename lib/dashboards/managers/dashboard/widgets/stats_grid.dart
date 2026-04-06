import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/event_manager_service.dart';
import '../dashboard_stats_provider.dart';

class StatsGrid extends ConsumerStatefulWidget {
  const StatsGrid({super.key});

  @override
  ConsumerState<StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends ConsumerState<StatsGrid> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.mintIce),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error loading stats: $err')),
      data: (stats) {
        final statsItems = [
          {
            'title': 'Active Teams',
            'count': stats['Active Teams'] ?? '0',
            'icon': FontAwesomeIcons.peopleGroup,
            'bgColor': AppColors.hunterGreen,
            'textColor': Colors.white,
            'subTextColor': Colors.white,
            'hasGraph': false,
          },
          {
            'title': 'Active Members',
            'count': stats['Active Members'] ?? '0',
            'icon': FontAwesomeIcons.userGroup,
            'bgColor': AppColors.hunterGreen,
            'textColor': Colors.white,
            'subTextColor': Colors.white,
            'hasGraph': false,
          },
          {
            'title': 'Accepted Proposals',
            'count': stats['Accepted Proposals'] ?? '0',
            'icon': FontAwesomeIcons.dollarSign,
            'bgColor': AppColors.hunterGreen,
            'textColor': Colors.white,
            'subTextColor': Colors.white,
            'hasGraph': false,
          },
          {
            'title': 'Pending Proposals',
            'count': stats['Pending Proposals'] ?? '0',
            'icon': FontAwesomeIcons.chartLine,
            'bgColor': AppColors.hunterGreen,
            'textColor': Colors.white,
            'subTextColor': Colors.white.withOpacity(0.9),
            'hasGraph': true,
          },
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
            final aspectRatio = constraints.maxWidth < 600 ? 1.4 : 1.1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: statsItems.length,
              itemBuilder: (context, index) {
                final item = statsItems[index];
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
          },
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
