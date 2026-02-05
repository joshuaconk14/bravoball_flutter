import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/friend_service.dart';
import '../../services/app_state_service.dart'; // ✅ ADDED: Import AppStateService for friend request count
import '../../models/friend_model.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/badge_widget.dart'; // ✅ ADDED: Import badge widget

class FriendsView extends StatefulWidget {
  const FriendsView({Key? key}) : super(key: key);

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Friend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  bool _isLoadingFriends = true;
  bool _isLoadingRequests = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      // Load data when switching tabs
      if (_tabController.index == 0 && _friends.isEmpty && !_isLoadingFriends) {
        _loadFriends();
      } else if (_tabController.index == 1 && _friendRequests.isEmpty && !_isLoadingRequests) {
        _loadFriendRequests();
      }
    });
    _loadFriends();
    _loadFriendRequests();
    // ✅ ADDED: Refresh friend request count when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFriendRequestCount();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoadingFriends = true;
      _errorMessage = null;
    });

    try {
      final friends = await FriendService.shared.getFriends();
      setState(() {
        _friends = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingFriends = false;
      });
    }
  }

  Future<void> _loadFriendRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final requests = await FriendService.shared.getFriendRequests();
      setState(() {
        _friendRequests = requests;
        _isLoadingRequests = false;
      });
      // ✅ ADDED: Refresh friend request count in AppStateService
      _refreshFriendRequestCount();
    } catch (e) {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  // ✅ ADDED: Helper method to refresh friend request count
  void _refreshFriendRequestCount() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    appState.refreshFriendRequestCount();
  }

  Future<void> _removeFriend(Friend friend) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.username} from your friends?'),
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
      try {
        // Note: We need friendship_id to remove, but we only have friend.id
        // For now, we'll need to handle this differently or update backend
        // This is a placeholder - actual implementation may need backend changes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend removal feature coming soon'),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove friend: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
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
          'Friends',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryYellow,
          labelColor: AppTheme.primaryDark,
          unselectedLabelColor: AppTheme.primaryGray,
          tabs: [
            const Tab(text: 'Friends'),
            Consumer<AppStateService>(
              builder: (context, appState, child) {
                return Tab(
                  child: BadgeWidget(
                    count: appState.friendRequestCount,
                    showBadge: appState.hasFriendRequests,
                    badgeSize: 12.0,
                    child: const Text('Requests'),
                  ),
                );
              },
            ),
            const Tab(text: 'Add'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _loadFriends,
            color: AppTheme.primaryYellow,
            child: _buildFriendsTab(),
          ),
          RefreshIndicator(
            onRefresh: _loadFriendRequests,
            color: AppTheme.primaryYellow,
            child: _buildRequestsTab(),
          ),
          _buildAddFriendsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
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
              'Loading friends...',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _selectedTabIndex == 0) {
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
                'Failed to load friends',
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
                  _loadFriends();
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

    if (_friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
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
        
        // Friends List
        ..._friends.map((friend) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFriendCard(friend),
          );
        }),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoadingRequests) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading requests...',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
              ),
            ),
          ],
        ),
      );
    }

    if (_friendRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_outlined,
                size: 64,
                color: AppTheme.primaryGray,
              ),
              const SizedBox(height: 16),
              Text(
                'No friend requests',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Friend requests will appear here',
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
        
        // Friend Requests List
        ..._friendRequests.map((request) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFriendRequestCard(request),
          );
        }),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAddFriendsTab() {
    return _AddFriendsTab(
      onFriendRequestSent: () {
        // Refresh requests tab when a request is sent
        _loadFriendRequests();
      },
    );
  }

  Widget _buildFriendCard(Friend friend) {
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              friend.username.isNotEmpty 
                  ? friend.username[0].toUpperCase()
                  : '?',
              style: AppTheme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          friend.displayName,
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          friend.username,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.primaryGray,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: AppTheme.primaryGray,
          ),
          onSelected: (value) {
            if (value == 'remove') {
              HapticUtils.mediumImpact();
              _removeFriend(friend);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: AppTheme.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Remove Friend',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard(FriendRequest request) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  request.username.isNotEmpty 
                      ? request.username[0].toUpperCase()
                      : '?',
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
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
                  Text(
                    request.username,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wants to be friends',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryGray,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accept Button
                IconButton(
                  onPressed: () => _acceptRequest(request),
                  icon: Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                  tooltip: 'Accept',
                ),
                // Decline Button
                IconButton(
                  onPressed: () => _declineRequest(request),
                  icon: Icon(Icons.cancel, color: AppTheme.error),
                  tooltip: 'Decline',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    HapticUtils.mediumImpact();
    try {
      final success = await FriendService.shared.acceptFriendRequest(request.requestId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.username} is now your friend!'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
        // Refresh both lists
        _loadFriends();
        _loadFriendRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _declineRequest(FriendRequest request) async {
    HapticUtils.mediumImpact();
    try {
      final success = await FriendService.shared.declineFriendRequest(request.requestId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request declined'),
            duration: const Duration(seconds: 2),
          ),
        );
        // Refresh requests list
        _loadFriendRequests();
        // ✅ ADDED: Refresh friend request count
        _refreshFriendRequestCount();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline request: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// Add Friends Tab Widget
class _AddFriendsTab extends StatefulWidget {
  final VoidCallback onFriendRequestSent;

  const _AddFriendsTab({required this.onFriendRequestSent});

  @override
  State<_AddFriendsTab> createState() => _AddFriendsTabState();
}

class _AddFriendsTabState extends State<_AddFriendsTab> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isSearching = false;
  bool _isSendingRequest = false;
  String? _searchError;
  int? _foundUserId;
  String? _foundUsername;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _searchError = 'Please enter a username';
        _foundUserId = null;
        _foundUsername = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _foundUserId = null;
      _foundUsername = null;
    });

    try {
      final userId = await FriendService.shared.lookupUserByUsername(username);
      if (userId != null) {
        setState(() {
          _foundUserId = userId;
          _foundUsername = username;
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchError = 'User not found';
          _foundUserId = null;
          _foundUsername = null;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'Failed to search user: ${e.toString()}';
        _foundUserId = null;
        _foundUsername = null;
        _isSearching = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_foundUserId == null) return;

    setState(() {
      _isSendingRequest = true;
    });

    try {
      final success = await FriendService.shared.sendFriendRequest(_foundUserId!);
      if (success) {
        HapticUtils.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to $_foundUsername!'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
        // Clear search
        _usernameController.clear();
        setState(() {
          _foundUserId = null;
          _foundUsername = null;
        });
        widget.onFriendRequestSent();
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('already pending')) {
        errorMessage = 'Friend request already sent';
      } else if (errorMessage.contains('already friends')) {
        errorMessage = 'You are already friends';
      } else if (errorMessage.contains('yourself')) {
        errorMessage = 'Cannot send friend request to yourself';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isSendingRequest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // Search Section
          Container(
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Search by Username',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username Input
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                      prefixIcon: Icon(Icons.search, color: AppTheme.primaryGray),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryGray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _searchUser(),
                  ),
                  
                  if (_searchError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _searchError!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Search Button
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Search'),
                  ),
                ],
              ),
            ),
          ),
          
          // Found User Section
          if (_foundUserId != null && _foundUsername != null) ...[
            const SizedBox(height: 20),
            Container(
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
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _foundUsername![0].toUpperCase(),
                              style: AppTheme.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _foundUsername!,
                                style: AppTheme.titleMedium.copyWith(
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'User found',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primaryGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSendingRequest ? null : _sendFriendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSendingRequest
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add, size: 20),
                                SizedBox(width: 8),
                                Text('Send Friend Request'),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
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
                    'Search for users by their username to send friend requests',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
