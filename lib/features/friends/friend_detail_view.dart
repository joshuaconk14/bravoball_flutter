import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/friend_model.dart';
import '../../services/friend_service.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/bravo_button.dart';

class FriendDetailView extends StatefulWidget {
  final Friend friend;

  const FriendDetailView({
    Key? key,
    required this.friend,
  }) : super(key: key);

  @override
  State<FriendDetailView> createState() => _FriendDetailViewState();
}

class _FriendDetailViewState extends State<FriendDetailView> {
  FriendDetail? _friendDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _loadFriendDetail();
  }

  Future<void> _loadFriendDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await FriendService.shared.getFriendDetail(widget.friend.id);
      setState(() {
        _friendDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFriend() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${widget.friend.username} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.primaryGray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticUtils.mediumImpact();
      setState(() {
        _isRemoving = true;
      });

      try {
        final success = await FriendService.shared.removeFriend(widget.friend.friendshipId);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.friend.username} has been removed from your friends'),
                backgroundColor: AppTheme.primaryGreen,
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pop(context, true); // Return true to indicate friend was removed
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove friend: ${e.toString()}'),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRemoving = false;
          });
        }
      }
    }
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
          'Friend Details',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading friend details...',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryGray,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
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
                          'Failed to load friend details',
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
                            _loadFriendDetail();
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
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      
                      // Avatar Section
                      _buildAvatarSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Stats Section
                      if (_friendDetail != null) _buildStatsSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Remove Friend Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: BravoButton(
                          text: _isRemoving ? 'Removing...' : 'Remove Friend',
                          onPressed: _isRemoving ? null : _removeFriend,
                          color: AppTheme.error,
                          backColor: AppTheme.errorDark,
                          textColor: Colors.white,
                          disabled: _isRemoving,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        // Large Avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.friend.displayBackgroundColor,
            border: Border.all(
              color: AppTheme.primaryYellow.withValues(alpha: 0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              widget.friend.displayAvatarPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: widget.friend.displayBackgroundColor,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Display Name
        Text(
          widget.friend.displayName,
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Username
        Text(
          '@${widget.friend.username}',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryGray,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    if (_friendDetail == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stats',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  value: '${_friendDetail!.points}',
                  label: 'Points',
                  icon: Icons.stars,
                  color: AppTheme.primaryYellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  value: '${_friendDetail!.sessionsCompleted}',
                  label: 'Sessions',
                  icon: Icons.fitness_center,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Streaks Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  value: '${_friendDetail!.currentStreak}',
                  label: 'Current Streak',
                  icon: Icons.local_fire_department,
                  color: AppTheme.secondaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  value: '${_friendDetail!.highestStreak}',
                  label: 'Highest Streak',
                  icon: Icons.emoji_events,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Rank Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: AppTheme.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rank',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${_friendDetail!.rank}',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Activity Section
          Text(
            'Activity',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Last Active & Total Time Row
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  label: 'Last Session',
                  value: _formatLastActive(_friendDetail!.lastActive),
                  icon: Icons.access_time,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  label: 'Total Practice',
                  value: _formatPracticeTime(_friendDetail!.totalPracticeMinutes),
                  icon: Icons.timer,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          
          // Favorite Drill Card
          if (_friendDetail!.favoriteDrill != null && 
              _friendDetail!.favoriteDrill!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.star,
                      color: AppTheme.primaryYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Favorite Drill',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _friendDetail!.favoriteDrill!,
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primaryGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) {
      return 'Never';
    }

    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  String _formatPracticeTime(int totalMinutes) {
    if (totalMinutes == 0) {
      return '0 min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    } else {
      return '${hours}h ${minutes}m';
    }
  }
}
