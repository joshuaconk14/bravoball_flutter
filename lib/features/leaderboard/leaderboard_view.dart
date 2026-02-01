import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/leaderboard_service.dart';
import '../../services/user_manager_service.dart';
import '../../models/leaderboard_model.dart';
import '../../utils/haptic_utils.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({Key? key}) : super(key: key);

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  List<LeaderboardEntry> _leaderboardEntries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await LeaderboardService.shared.getLeaderboard();
      setState(() {
        _leaderboardEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool _isCurrentUser(LeaderboardEntry entry) {
    final userManager = UserManagerService.instance;
    return entry.username == userManager.username;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryDark),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Leaderboard',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeaderboard,
        color: AppTheme.primaryYellow,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading leaderboard...',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load leaderboard',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  HapticUtils.mediumImpact();
                  _loadLeaderboard();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_leaderboardEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: AppTheme.primaryGray,
              ),
              const SizedBox(height: 16),
              Text(
                'No friends yet',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add friends to compete on the leaderboard!',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      children: [
        const SizedBox(height: 10),
        
        // Trophy Icon Header
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              size: 48,
              color: AppTheme.primaryYellow,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Leaderboard Entries
        ..._leaderboardEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final leaderboardEntry = entry.value;
          final isCurrentUser = _isCurrentUser(leaderboardEntry);
          
          return Padding(
            padding: EdgeInsets.only(bottom: index < _leaderboardEntries.length - 1 ? 12 : 0),
            child: _buildLeaderboardEntry(leaderboardEntry, isCurrentUser),
          );
        }),
        
        const SizedBox(height: 24),
        
        // Info Message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete more training sessions to increase your rank and points!',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, bool isCurrentUser) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? AppTheme.primaryYellow.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: AppTheme.primaryYellow, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? AppTheme.primaryYellow
                    : AppTheme.primaryGray.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  '#${entry.rank}',
                  style: AppTheme.titleMedium.copyWith(
                    color: isCurrentUser 
                        ? AppTheme.primaryDark
                        : AppTheme.primaryGray,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.username,
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryYellow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 16,
                        color: AppTheme.primaryYellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.points} points',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryGray,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.sessionsCompleted} sessions',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
