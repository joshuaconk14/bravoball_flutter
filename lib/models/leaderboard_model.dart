/// Leaderboard Models
/// Models for leaderboard data structures

/// Leaderboard entry model matching backend response structure
class LeaderboardEntry {
  final int id;
  final String username;
  final int points;
  final int sessionsCompleted;
  final int rank;

  LeaderboardEntry({
    required this.id,
    required this.username,
    required this.points,
    required this.sessionsCompleted,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      points: json['points'] ?? 0,
      sessionsCompleted: json['sessions_completed'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'points': points,
      'sessions_completed': sessionsCompleted,
      'rank': rank,
    };
  }
}
