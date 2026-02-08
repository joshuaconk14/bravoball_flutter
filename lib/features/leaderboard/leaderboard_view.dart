import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ ADDED: For kDebugMode
import '../../constants/app_theme.dart';
import '../../services/leaderboard_service.dart';
import '../../services/user_manager_service.dart';
import '../../services/friend_service.dart'; // ✅ ADDED: Import FriendService
import '../../models/leaderboard_model.dart';
import '../../models/friend_model.dart'; // ✅ ADDED: Import Friend model
import '../../utils/haptic_utils.dart';
import '../../utils/avatar_helper.dart'; // ✅ ADDED: Import AvatarHelper for avatar utilities
import '../../widgets/info_popup_widget.dart'; // ✅ ADDED: Import InfoPopupWidget
import '../friends/friend_detail_view.dart'; // ✅ ADDED: Import FriendDetailView

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({Key? key}) : super(key: key);

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Friends leaderboard state
  List<LeaderboardEntry> _friendsLeaderboardEntries = [];
  bool _isLoadingFriends = true;
  String? _friendsErrorMessage;
  
  // World leaderboard state
  WorldLeaderboardResponse? _worldLeaderboardResponse;
  bool _isLoadingWorld = false; // ✅ FIXED: Start as false, only true when actively loading
  String? _worldErrorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadFriendsLeaderboard();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      // Tab change is complete (not animating)
      if (_tabController.index == 1 && _worldLeaderboardResponse == null && !_isLoadingWorld) {
        if (kDebugMode) {
          print('🌍 LeaderboardView: Switching to World tab, loading world leaderboard...');
        }
        _loadWorldLeaderboard();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendsLeaderboard() async {
    setState(() {
      _isLoadingFriends = true;
      _friendsErrorMessage = null;
    });

    try {
      final entries = await LeaderboardService.shared.getLeaderboard();
      setState(() {
        _friendsLeaderboardEntries = entries;
        _isLoadingFriends = false;
      });
    } catch (e) {
      setState(() {
        _friendsErrorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingFriends = false;
      });
    }
  }

  Future<void> _loadWorldLeaderboard() async {
    if (kDebugMode) {
      print('🌍 LeaderboardView: Starting to load world leaderboard...');
    }
    
    setState(() {
      _isLoadingWorld = true;
      _worldErrorMessage = null;
    });

    try {
      final response = await LeaderboardService.shared.getWorldLeaderboard();
      if (kDebugMode) {
        print('✅ LeaderboardView: World leaderboard loaded successfully');
        print('   Top 50 entries: ${response.top50.length}');
        print('   User rank: #${response.userRank.rank}');
      }
      setState(() {
        _worldLeaderboardResponse = response;
        _isLoadingWorld = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ LeaderboardView: Error loading world leaderboard: $e');
      }
      setState(() {
        _worldErrorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingWorld = false;
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
        automaticallyImplyLeading: false, // ✅ REMOVED: No back button since it's in bottom nav
        title: Text(
          'Leaderboard',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: AppTheme.primaryGray,
            ),
            onPressed: () {
              HapticUtils.lightImpact();
              _showLeaderboardInfo();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryYellow,
          labelColor: AppTheme.primaryDark,
          unselectedLabelColor: AppTheme.primaryGray,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'World'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _loadFriendsLeaderboard,
            color: AppTheme.primaryYellow,
            child: _buildFriendsContent(),
          ),
          RefreshIndicator(
            onRefresh: _loadWorldLeaderboard,
            color: AppTheme.primaryYellow,
            child: _buildWorldContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsContent() {
    if (_isLoadingFriends) {
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

    if (_friendsErrorMessage != null) {
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
                _friendsErrorMessage!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  HapticUtils.mediumImpact();
                  _loadFriendsLeaderboard();
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

    if (_friendsLeaderboardEntries.isEmpty) {
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
        ..._friendsLeaderboardEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final leaderboardEntry = entry.value;
          final isCurrentUser = _isCurrentUser(leaderboardEntry);
          
          return Padding(
            padding: EdgeInsets.only(bottom: index < _friendsLeaderboardEntries.length - 1 ? 12 : 0),
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

  Widget _buildWorldContent() {
    if (_isLoadingWorld) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading world leaderboard...',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
              ),
            ),
          ],
        ),
      );
    }

    if (_worldErrorMessage != null) {
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
                'Failed to load world leaderboard',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _worldErrorMessage!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  HapticUtils.mediumImpact();
                  _loadWorldLeaderboard();
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

    if (_worldLeaderboardResponse == null) {
      return const SizedBox.shrink();
    }

    final response = _worldLeaderboardResponse!;
    final top50 = response.top50;
    final userRank = response.userRank;
    final isUserInTop50 = response.isUserInTop50;

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
              Icons.public,
              size: 48,
              color: AppTheme.primaryYellow,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Top 50 Message
        Center(
          child: Text(
            'Top 50 Players Worldwide',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Center(
          child: Text(
            'Ranked by total points',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primaryGray,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Top 50 Leaderboard Entries
        ...top50.asMap().entries.map((entry) {
          final index = entry.key;
          final leaderboardEntry = entry.value;
          final isCurrentUser = _isCurrentUser(leaderboardEntry);
          
          return Padding(
            padding: EdgeInsets.only(bottom: index < top50.length - 1 ? 12 : 0),
            child: _buildLeaderboardEntry(
              leaderboardEntry, 
              isCurrentUser,
              isFriend: false, // World leaderboard entries may not be friends
            ),
          );
        }),
        
        // User Rank Card (if not in top 50)
        if (!isUserInTop50) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryYellow,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: AppTheme.primaryYellow,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Rank',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLeaderboardEntry(userRank, true),
              ],
            ),
          ),
        ],
        
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
                  'Complete more training sessions to climb the global leaderboard!',
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

  Widget _buildLeaderboardEntry(
    LeaderboardEntry entry, 
    bool isCurrentUser, {
    bool isFriend = false,
  }) {
    return InkWell(
      onTap: () {
        if (isCurrentUser) return; // Don't navigate if it's the current user
        HapticUtils.lightImpact();
        _navigateToProfile(entry, isFriend: isFriend);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            // Avatar with Rank Badge
            Stack(
              children: [
                // Avatar Circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.displayBackgroundColor,
                    border: Border.all(
                      color: isCurrentUser 
                          ? AppTheme.primaryYellow
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      entry.displayAvatarPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to default icon if image fails to load
                        return Container(
                          color: entry.displayBackgroundColor,
                          child: const Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Rank Badge Overlay
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCurrentUser 
                          ? AppTheme.primaryYellow
                          : AppTheme.primaryGray,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.rank}',
                        style: AppTheme.bodySmall.copyWith(
                          color: isCurrentUser 
                              ? AppTheme.primaryDark
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }

  Future<void> _navigateToProfile(LeaderboardEntry entry, {required bool isFriend}) async {
    try {
      if (isFriend) {
        // For friends leaderboard, fetch friend data and navigate to FriendDetailView
        final friends = await FriendService.shared.getFriends();
        final friend = friends.firstWhere(
          (f) => f.id == entry.id,
          orElse: () => _createFriendFromEntry(entry),
        );
        
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FriendDetailView(friend: friend),
            ),
          );
        }
      } else {
        // For world leaderboard, try to get friend detail (if they're a friend)
        // Otherwise show a public profile or handle gracefully
        try {
          final friendDetail = await FriendService.shared.getFriendDetail(entry.id);
          if (friendDetail != null && mounted) {
            // Convert FriendDetail to Friend for navigation
            final friend = Friend(
              id: friendDetail.id,
              friendshipId: friendDetail.friendshipId,
              username: friendDetail.username,
              email: friendDetail.email,
              firstName: friendDetail.firstName,
              lastName: friendDetail.lastName,
              avatarPath: friendDetail.avatarPath,
              avatarBackgroundColor: friendDetail.avatarBackgroundColor,
            );
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FriendDetailView(friend: friend),
              ),
            );
          } else {
            // Not a friend - show a message or create public profile view
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${entry.username} is not your friend. Add them to view their profile!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          // If 404 or not a friend, show message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${entry.username} is not your friend. Add them to view their profile!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Friend _createFriendFromEntry(LeaderboardEntry entry) {
    // Create a minimal Friend object from LeaderboardEntry
    // This is used as fallback if friend is not found in friends list
    return Friend(
      id: entry.id,
      friendshipId: 0, // Will be fetched when detail loads
      username: entry.username,
      email: '', // Not available in leaderboard entry
      avatarPath: entry.avatarPath,
      avatarBackgroundColor: entry.avatarBackgroundColor,
    );
  }

  void _showLeaderboardInfo() {
    InfoPopupWidget.show(
      context,
      title: 'About the Leaderboard',
      description: 'Compete with friends and players worldwide! See how you rank based on your training progress.\n\n🏆 **How Points Work:**\nComplete training sessions to earn points. Each session you finish adds to your total score.\n\n📅 **Daily Limit:**\nYou can earn points for completing one session per day. Additional sessions completed on the same day won\'t count toward your points, but keep practicing to improve your skills!\n\n👥 **Friends Leaderboard:**\nSee how you rank among your friends. Add friends to compete and motivate each other!\n\n🌍 **World Leaderboard:**\nView the top 50 players globally and see where you rank among all BravoBall users.\n\nKeep training to climb the ranks!',
      riveFileName: 'Bravo_Animation.riv',
    );
  }
}
