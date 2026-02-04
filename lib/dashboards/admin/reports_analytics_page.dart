import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsAnalyticsPage extends StatefulWidget {
  const ReportsAnalyticsPage({super.key});

  @override
  State<ReportsAnalyticsPage> createState() => _ReportsAnalyticsPageState();
}

class _ReportsAnalyticsPageState extends State<ReportsAnalyticsPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 900;
        final isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(isMobile),
              const SizedBox(height: 24),

              // Summary Cards
              _buildSummaryCards(isMobile, constraints.maxWidth),
              const SizedBox(height: 24),

              // Charts Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chart Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTabButton('User Growth', 0),
                          _buildTabButton('Event Performance', 1),
                          _buildTabButton('User Distribution', 2),
                          _buildTabButton('Engagement', 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Chart
                    SizedBox(
                      height: 300,
                      child: _selectedTabIndex == 1 
                        ? _buildEventPerformanceChart()
                        : _buildLineChart(),
                    ),
                    const SizedBox(height: 16),

                     // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _selectedTabIndex == 1 
                      ? [
                         _buildLegendItem(const Color(0xFF4285F4), 'Events Hosted'), // Blue
                         const SizedBox(width: 16),
                         _buildLegendItem(const Color(0xFF0F9D58), 'Total Attendance'), // Green
                      ]
                      : [
                         _buildLegendItem(Colors.blue, 'Volunteers'),
                         const SizedBox(width: 16),
                         _buildLegendItem(Colors.purple, 'Managers'),
                         const SizedBox(width: 16),
                         _buildLegendItem(Colors.pink, 'Hosts'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _selectedTabIndex == 1
                        ? 'Event performance metrics showing correlation between number of events and attendance rates.'
                        : 'User growth across all categories showing steady upward trend with 12% increase in volunteers this month.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          const Text(
            'Reports & Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'View insights and performance metrics',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Export Report'),
            ),
          ),
        ] else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reports & Analytics',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View insights and performance metrics',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Export Report'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSummaryCards(bool isMobile, double width) {
    final cardWidth = isMobile ? width : (width - 48 - 48) / 4; // Approx width calc

    final cards = [
      _buildInfoCard('Total Users', '155', '+12% from last month', Icons.people_outline, Colors.blue),
      _buildInfoCard('Total Events', '128', '+18% from last month', Icons.calendar_today, Colors.purple),
      _buildInfoCard('Avg Attendance', '41', '+8% from last month', Icons.trending_up, Colors.orange),
      _buildInfoCard('Completion Rate', '94%', '+3% from last month', Icons.verified_outlined, Colors.green),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: c,
        )).toList(),
      );
    } else {
      // Use Table or Row with Expanded for Desktop
       return Row(
         children: cards.map((c) => Expanded(
           child: Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: c,
           ),
         )).toList(),
       );
    }
  }

  Widget _buildInfoCard(String title, String value, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
              Icon(icon, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            trend,
            style: TextStyle(color: Colors.green[600], fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: isSelected ? Border.all(color: Colors.grey[300]!) : null,
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 30, // Adjusted based on max Y 120
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200],
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[200],
              strokeWidth: 1,
              dashArray: [5, 5], // Dashed vertical lines
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 12);
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Jul'; break;
                  case 1: text = 'Aug'; break;
                  case 2: text = 'Sep'; break;
                  case 3: text = 'Oct'; break;
                  case 4: text = 'Nov'; break;
                  case 5: text = 'Dec'; break;
                  case 6: text = 'Jan'; break;
                  default: return Container();
                }
                return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 120, // Based on image 120 is top
        lineBarsData: [
          // Volunteers (Blue)
          LineChartBarData(
            spots: [
              FlSpot(0, 45),
              FlSpot(1, 48),
              FlSpot(2, 65),
              FlSpot(3, 72),
              FlSpot(4, 90),
              FlSpot(5, 105),
              FlSpot(6, 120),
            ],
            isCurved: true, // Smooth curve
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
          // Managers (Purple)
          LineChartBarData(
            spots: [
              FlSpot(0, 8),
              FlSpot(1, 10),
              FlSpot(2, 12),
              FlSpot(3, 15),
              FlSpot(4, 16),
              FlSpot(5, 18),
              FlSpot(6, 20),
            ],
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
          // Hosts (Red/Pink)
          LineChartBarData(
            spots: [
              FlSpot(0, 3),
              FlSpot(1, 6),
              FlSpot(2, 8),
              FlSpot(3, 10),
              FlSpot(4, 11),
              FlSpot(5, 13),
              FlSpot(6, 15),
            ],
            isCurved: true,
            color: Colors.pink,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPerformanceChart() {
    // Dual Axis Simulation Strategy
    // Left Axis: Events Hosted (0-28)
    // Right Axis: Total Attendance (0-1200)
    // To plot on same chart, normalize Right Axis data to match Left Axis scale.
    // Scale Ratio = 1200 / 28 ≈ 42.85
    // plottedValue = actualValue / 42.85

    const double maxY = 28;
    const double rightMaxY = 1200;
    const double scaleRatio = rightMaxY / maxY;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxY,
        minY: 0,
        groupsSpace: 12,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = '';
              String value = '';
              if (rodIndex == 0) {
                label = 'Events';
                value = rod.toY.round().toString();
              } else {
                label = 'Attendance';
                // Reverse calculation to show actual value in tooltip
                value = (rod.toY * scaleRatio).round().toString();
              }
              return BarTooltipItem(
                '$label\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: rod.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 12);
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Jul'; break;
                  case 1: text = 'Aug'; break;
                  case 2: text = 'Sep'; break;
                  case 3: text = 'Oct'; break;
                  case 4: text = 'Nov'; break;
                  case 5: text = 'Dec'; break;
                  case 6: text = 'Jan'; break;
                  default: return Container();
                }
                return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7, // 0, 7, 14, 21, 28
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7, // Aligned with Left Axis steps
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Map the internal Y value back to the Right Axis scale
                // value 7 -> 300, 14 -> 600, 21 -> 900, 28 -> 1200
                final actualValue = (value * scaleRatio).toInt();
                return Text(
                  actualValue.toString(),
                  style: const TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 7,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, 12, 450 / scaleRatio), // Jul
          _makeGroupData(1, 15, 580 / scaleRatio), // Aug
          _makeGroupData(2, 18, 750 / scaleRatio), // Sep
          _makeGroupData(3, 16, 700 / scaleRatio), // Oct
          _makeGroupData(4, 22, 950 / scaleRatio), // Nov
          _makeGroupData(5, 20, 850 / scaleRatio), // Dec
          _makeGroupData(6, 25, 1100 / scaleRatio), // Jan
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: const Color(0xFF4285F4),
          width: 16,
          borderRadius: BorderRadius.circular(2),
        ),
        BarChartRodData(
          toY: y2,
          color: const Color(0xFF0F9D58),
          width: 16,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}
