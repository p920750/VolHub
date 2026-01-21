import 'package:flutter/material.dart';
import 'package:vol_hub/core/theme.dart';

class DashboardCharts extends StatelessWidget {
  const DashboardCharts({super.key});

  @override
  Widget build(BuildContext context) {
    // Only showing TrendChart as Member Role card (SalesChart) was removed.
    return const TrendChart();
  }
}

class TrendChart extends StatelessWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activity Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.midnightBlue, borderRadius: BorderRadius.circular(20)),
                child: const Text('This Year', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                final h1 = 50 + (index * 20) % 100;
                final h2 = 80 + (index * 15) % 80;
                final h3 = 30 + (index * 30) % 70;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _bar(h1.toDouble(), AppColors.mintIce),
                        const SizedBox(width: 2),
                        _bar(h2.toDouble(), AppColors.hunterGreen),
                         const SizedBox(width: 2),
                        _bar(h3.toDouble(), AppColors.midnightBlue),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index], 
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return Container(
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
