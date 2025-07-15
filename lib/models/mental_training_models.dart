class MentalTrainingQuote {
  final int id;
  final String content;
  final String author;
  final String type;
  final int displayDuration;

  MentalTrainingQuote({
    required this.id,
    required this.content,
    required this.author,
    required this.type,
    required this.displayDuration,
  });

  factory MentalTrainingQuote.fromJson(Map<String, dynamic> json) {
    return MentalTrainingQuote(
      id: json['id'],
      content: json['content'],
      author: json['author'],
      type: json['type'],
      displayDuration: json['display_duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author,
      'type': type,
      'display_duration': displayDuration,
    };
  }
}

class MentalTrainingSession {
  final int? id;
  final int? userId;
  final DateTime? date;
  final int durationMinutes;
  final String sessionType;

  MentalTrainingSession({
    this.id,
    this.userId,
    this.date,
    required this.durationMinutes,
    this.sessionType = 'mental_training',
  });

  factory MentalTrainingSession.fromJson(Map<String, dynamic> json) {
    return MentalTrainingSession(
      id: json['id'],
      userId: json['user_id'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      durationMinutes: json['duration_minutes'],
      sessionType: json['session_type'] ?? 'mental_training',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'session_type': sessionType,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'duration_minutes': durationMinutes,
      'session_type': sessionType,
    };
  }
}

class MentalTrainingSessionsToday {
  final int sessionsToday;
  final int totalMinutesToday;
  final List<MentalTrainingSession> sessions;

  MentalTrainingSessionsToday({
    required this.sessionsToday,
    required this.totalMinutesToday,
    required this.sessions,
  });

  factory MentalTrainingSessionsToday.fromJson(Map<String, dynamic> json) {
    return MentalTrainingSessionsToday(
      sessionsToday: json['sessions_today'],
      totalMinutesToday: json['total_minutes_today'],
      sessions: (json['sessions'] as List)
          .map((session) => MentalTrainingSession.fromJson(session))
          .toList(),
    );
  }
} 