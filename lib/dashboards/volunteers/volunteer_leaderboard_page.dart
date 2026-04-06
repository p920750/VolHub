import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/volunteer_service.dart';
import '../../widgets/moving_balls_animation.dart';
import 'volunteer_colors.dart';

class VolunteerLeaderboardPage extends StatefulWidget {
  const VolunteerLeaderboardPage({super.key});

  @override
  State<VolunteerLeaderboardPage> createState() => _VolunteerLeaderboardPageState();
}

class _VolunteerLeaderboardPageState extends State<VolunteerLeaderboardPage> {
  List<Map<String, dynamic>> _leaderboardData = [];
  int _userRank = 0;
  double _userScore = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final data = await VolunteerService.getLeaderboardData();
    final rank = await VolunteerService.getUserRank(user.id);
    final stats = await VolunteerService.getVolunteerStats(user.id);

    if (mounted) {
      setState(() {
        _leaderboardData = data;
        _userRank = rank;
        _userScore = (stats['rank_score'] ?? 0.0).toDouble();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VolunteerColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const MovingBallsAnimation(),
                      _buildUserRankCard(),
                      _buildLeaderboardHeader(),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final volunteer = _leaderboardData[index];
                        return _buildLeaderboardItem(index + 1, volunteer);
                      },
                      childCount: _leaderboardData.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildUserRankCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VolunteerColors.primaryNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: VolunteerColors.primaryNavy.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Your Rank', '#$_userRank', Icons.emoji_events),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem('Total Score', _userScore.toStringAsFixed(0), Icons.star),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildLeaderboardHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text('Top Volunteers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: VolunteerColors.textPrimary)),
          Spacer(),
          Text('Rank Score', style: TextStyle(fontSize: 14, color: VolunteerColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, Map<String, dynamic> volunteer) {
    final bool isTop3 = rank <= 3;
    final String photo = volunteer['profile_photo'] ?? '';
    final String name = volunteer['full_name'] ?? 'Unknown';
    final double score = (volunteer['rank_score'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isTop3 ? Colors.amber[700] : VolunteerColors.textSecondary,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty ? Text(name[0]) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: VolunteerColors.textPrimary),
            ),
          ),
          Text(
            score.toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: VolunteerColors.primaryGreen),
          ),
        ],
      ),
    );
  }
}
