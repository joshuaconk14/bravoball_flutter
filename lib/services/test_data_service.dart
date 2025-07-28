import '../models/drill_model.dart';
import '../models/editable_drill_model.dart';
import '../constants/app_theme.dart';
import '../config/app_config.dart';
import 'dart:math';

/// Pagination Response Model
class PaginatedDrillResponse {
  final List<DrillModel> drills;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedDrillResponse({
    required this.drills,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
}

/// Search Filters for API simulation
class DrillSearchFilters {
  final String? query;
  final String? skill;
  final String? difficulty;
  final String? trainingStyle;
  final List<String>? equipment;
  final int? maxDuration;
  final int page;
  final int pageSize;

  DrillSearchFilters({
    this.query,
    this.skill,
    this.difficulty,
    this.trainingStyle,
    this.equipment,
    this.maxDuration,
    this.page = 1,
    this.pageSize = 20,
  });
}

/// Enhanced Test Data Service
/// Simulates real backend behavior with proper pagination, loading states, and delays
class TestDataService {
  // Private constructor for singleton
  TestDataService._();
  static final TestDataService _instance = TestDataService._();
  static TestDataService get instance => _instance;

  // Simulate API response times
  static const int _minApiDelayMs = 800;
  static const int _maxApiDelayMs = 2000;
  
  // Pagination settings
  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 50;

  /// Generate comprehensive test drill database (30+ drills)
  static List<DrillModel> _getExpandedTestDrills() {
    return [
      // DRIBBLING DRILLS
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Cone Weaving Mastery',
        description: 'Master close control by weaving through cones with both feet. Focus on tight turns and quick changes of direction.',
        skill: 'Dribbling',
        subSkills: ['Ball Control', 'Agility', 'Both Feet'],
        difficulty: 'Beginner',
        equipment: ['Cones', 'Ball'],
        trainingStyle: 'low intensity',
        duration: 12,
        reps: 5,
        sets: 3,
        videoUrl: 'https://example.com/cone-weaving',
        instructions: [
          'Set up 6-8 cones in a straight line, 2 yards apart',
          'Dribble through using inside and outside of both feet',
          'Focus on keeping the ball close to your feet',
          'Complete 5 rounds, timing yourself'
        ],
        tips: [
          'Keep your head up to see the next cone',
          'Use small touches to maintain control',
          'Accelerate out of the last cone'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),
      
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440002',
        title: 'Ronaldinho Rainbow Flick',
        description: 'Learn the iconic rainbow flick to beat defenders in style. Practice the perfect touch and timing.',
        skill: 'Dribbling',
        subSkills: ['Skill Moves', 'Flair', 'Timing'],
        difficulty: 'Advanced',
        equipment: ['Ball', 'Wall'],
        trainingStyle: 'low intensity',
        duration: 20,
        reps: 10,
        sets: 4,
        videoUrl: 'https://example.com/rainbow-flick',
        instructions: [
          'Start with the ball between your feet',
          'Use your dominant foot to roll the ball up your leg',
          'Flick the ball over your head with your heel',
          'Practice against a wall first'
        ],
        tips: [
          'Start slowly and build up speed',
          'Keep your balance throughout the move',
          'Use this move sparingly in games'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440003',
        title: 'Speed Dribbling Circuit',
        description: 'Develop explosive pace while maintaining ball control. Perfect for beating defenders on the break.',
        skill: 'Dribbling',
        subSkills: ['Speed', 'Control', 'Acceleration'],
        difficulty: 'Intermediate',
        equipment: ['Cones', 'Ball', 'Stopwatch'],
        trainingStyle: 'low intensity',
        duration: 15,
        reps: 6,
        sets: 3,
        videoUrl: 'https://example.com/speed-dribbling',
        instructions: [
          'Set up 20-yard sprint with cones every 5 yards',
          'Dribble at maximum speed while maintaining control',
          'Touch the ball every 2-3 steps',
          'Rest 30 seconds between runs'
        ],
        tips: [
          'Use the laces for longer touches',
          'Keep your head up to see ahead',
          'Practice with both feet'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      // PASSING DRILLS
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440004',
        title: 'Precision Passing Gates',
        description: 'Improve passing accuracy by hitting targets of different sizes. Build confidence in your distribution.',
        skill: 'Passing',
        subSkills: ['Accuracy', 'Weight of Pass', 'Vision'],
        difficulty: 'Beginner',
        equipment: ['Cones', 'Ball', 'Targets'],
        trainingStyle: 'low intensity',
        duration: 18,
        reps: 10,
        sets: 3,
        videoUrl: 'https://example.com/precision-passing',
        instructions: [
          'Set up 5 gates of different sizes using cones',
          'Pass the ball through each gate from 15 yards',
          'Start with larger gates and progress to smaller ones',
          'Score 8/10 before moving to next size'
        ],
        tips: [
          'Use the inside of your foot for accuracy',
          'Follow through toward your target',
          'Keep your standing foot planted'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440005',
        title: 'Long Range Distribution',
        description: 'Master long passes like a center-back. Switch play and find teammates across the field.',
        skill: 'Passing',
        subSkills: ['Long Pass', 'Technique', 'Power'],
        difficulty: 'Advanced',
        equipment: ['Ball', 'Targets', 'Markers'],
        trainingStyle: 'low intensity',
        duration: 25,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/long-passing',
        instructions: [
          'Set up targets at 30, 40, and 50 yards',
          'Use inside foot for accuracy, laces for power',
          'Hit 5 successful passes at each distance',
          'Focus on the flight and trajectory'
        ],
        tips: [
          'Lean back slightly for elevation',
          'Strike through the center of the ball',
          'Follow through with your kicking leg'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440006',
        title: 'One-Touch Passing Wall',
        description: 'Develop quick passing under pressure. Perfect for tight spaces and quick combinations.',
        skill: 'Passing',
        subSkills: ['Quick Passing', 'First Touch', 'Pressure'],
        difficulty: 'Intermediate',
        equipment: ['Ball', 'Wall'],
        trainingStyle: 'low intensity',
        duration: 16,
        reps: 50,
        sets: 2,
        videoUrl: 'https://example.com/one-touch-passing',
        instructions: [
          'Stand 5 yards from a wall',
          'Pass the ball and control the return in one touch',
          'Vary the angle and power of your passes',
          'Complete 50 successful one-touch passes'
        ],
        tips: [
          'Get your body position right early',
          'Use the inside of your foot for control',
          'Keep the ball moving quickly'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      // SHOOTING DRILLS
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440007',
        title: 'Power Shot Technique',
        description: 'Learn to strike the ball with power and precision. Become a threat from outside the box.',
        skill: 'Shooting',
        subSkills: ['Power', 'Accuracy', 'Technique'],
        difficulty: 'Intermediate',
        equipment: ['Ball', 'Goal', 'Markers'],
        trainingStyle: 'high intensity',
        duration: 22,
        reps: 10,
        sets: 3,
        videoUrl: 'https://example.com/power-shooting',
        instructions: [
          'Set up 5 shooting positions around the penalty area',
          'Focus on striking through the center of the ball',
          'Aim for the corners with power',
          'Take 10 shots from each position'
        ],
        tips: [
          'Plant your standing foot firmly',
          'Keep your head steady and eyes on the ball',
          'Follow through in the direction of your target'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440008',
        title: 'Finesse Shot Mastery',
        description: 'Master the art of placement over power. Learn to curl shots into the top corner.',
        skill: 'Shooting',
        subSkills: ['Placement', 'Curve', 'Finesse'],
        difficulty: 'Advanced',
        equipment: ['Ball', 'Goal', 'Cones'],
        trainingStyle: 'medium intensity',
        duration: 20,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/finesse-shooting',
        instructions: [
          'Set up cones in the corners of the goal',
          'Practice curling the ball using the inside of your foot',
          'Focus on placement rather than power',
          'Hit each corner 5 times successfully'
        ],
        tips: [
          'Use the inside of your foot for curve',
          'Lean into the shot for better accuracy',
          'Practice with both feet'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440009',
        title: 'Volley Technique Training',
        description: 'Perfect your volleying technique for spectacular goals. Control and power in one motion.',
        skill: 'Shooting',
        subSkills: ['Volleys', 'Timing', 'Balance'],
        difficulty: 'Advanced',
        equipment: ['Ball', 'Goal', 'Wall'],
        trainingStyle: 'high intensity',
        duration: 24,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/volley-shooting',
        instructions: [
          'Throw the ball up and volley it toward the goal',
          'Focus on timing and balance',
          'Start with easier chest-height balls',
          'Progress to more difficult angles'
        ],
        tips: [
          'Keep your eye on the ball until contact',
          'Use your arms for balance',
          'Strike through the middle of the ball'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      // FIRST TOUCH DRILLS
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440010',
        title: 'Wall Control Challenge',
        description: 'Master your first touch using a wall. Control balls coming at different angles and speeds.',
        skill: 'First Touch',
        subSkills: ['Ball Control', 'Reaction', 'Softness'],
        difficulty: 'Beginner',
        equipment: ['Ball', 'Wall'],
        trainingStyle: 'low intensity',
        duration: 14,
        reps: 5,
        sets: 3,
        videoUrl: 'https://example.com/wall-control',
        instructions: [
          'Stand 8 yards from a wall',
          'Pass the ball against the wall and control the return',
          'Use different parts of your foot for control',
          'Vary the power and angle of your passes'
        ],
        tips: [
          'Cushion the ball with a soft touch',
          'Get your body in line with the ball',
          'Practice with both feet equally'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440011',
        title: 'Aerial Control Mastery',
        description: 'Control balls from the air like a professional. Essential for modern soccer.',
        skill: 'First Touch',
        subSkills: ['Aerial Control', 'Cushioning', 'Body Position'],
        difficulty: 'Intermediate',
        equipment: ['Ball'],
        trainingStyle: 'low intensity',
        duration: 18,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/aerial-control',
        instructions: [
          'Throw the ball high in the air',
          'Control it with different parts of your body',
          'Use chest, thigh, and foot for control',
          'Keep the ball close after your first touch'
        ],
        tips: [
          'Watch the ball all the way down',
          'Relax your body to cushion the ball',
          'Get your body behind the ball'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440012',
        title: 'Pressure Cooker First Touch',
        description: 'Perfect your first touch under pressure. Simulate game-like conditions.',
        skill: 'First Touch',
        subSkills: ['Pressure', 'Quick Feet', 'Composure'],
        difficulty: 'Advanced',
        equipment: ['Ball', 'Cones', 'Wall'],
        trainingStyle: 'high intensity',
        duration: 16,
        reps: 30,
        sets: 2,
        videoUrl: 'https://example.com/pressure-touch',
        instructions: [
          'Set up in a small 5x5 yard box',
          'Pass the ball against the wall from different angles',
          'Control and pass again within 2 touches',
          'Complete 30 successful sequences'
        ],
        tips: [
          'Stay calm under pressure',
          'Use the space efficiently',
          'Keep your head up to see options'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      // DEFENDING DRILLS
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440013',
        title: 'Defensive Positioning Basics',
        description: 'Learn proper defensive stance and positioning. Foundation of good defending.',
        skill: 'Defending',
        subSkills: ['Positioning', 'Stance', 'Awareness'],
        difficulty: 'Beginner',
        equipment: ['Cones', 'Ball'],
        trainingStyle: 'low intensity',
        duration: 15,
        reps: 5,
        sets: 3,
        videoUrl: 'https://example.com/defensive-positioning',
        instructions: [
          'Set up a 10x10 yard box with cones',
          'Practice defensive stance - low, balanced',
          'Shadow an imaginary attacker',
          'Focus on staying between attacker and goal'
        ],
        tips: [
          'Stay on the balls of your feet',
          'Keep your center of gravity low',
          'Don\'t dive in too early'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440014',
        title: 'Tackling Technique',
        description: 'Master the art of clean tackling. Win the ball without fouling.',
        skill: 'Defending',
        subSkills: ['Tackling', 'Timing', 'Technique'],
        difficulty: 'Intermediate',
        equipment: ['Ball', 'Cones'],
        trainingStyle: 'low intensity',
        duration: 20,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/tackling-technique',
        instructions: [
          'Practice slide tackles on a stationary ball',
          'Focus on timing and technique',
          'Win the ball cleanly every time',
          'Progress to moving balls'
        ],
        tips: [
          'Time your tackle perfectly',
          'Use the inside of your foot',
          'Get your body behind the ball'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440015',
        title: 'Jockeying and Delay',
        description: 'Learn to delay attackers and force them into poor decisions. Patience is key.',
        skill: 'Defending',
        subSkills: ['Jockeying', 'Patience', 'Positioning'],
        difficulty: 'Advanced',
        equipment: ['Cones', 'Ball'],
        trainingStyle: 'low intensity',
        duration: 18,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/jockeying',
        instructions: [
          'Set up a channel using cones',
          'Practice jockeying backward slowly',
          'Force the attacker to one side',
          'Wait for the right moment to tackle'
        ],
        tips: [
          'Be patient and don\'t rush',
          'Show the attacker where you want them to go',
          'Stay balanced and ready to react'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      // FITNESS DRILLS
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440016',
        title: 'Sprint Interval Training',
        description: 'Build explosive speed and endurance. Essential for modern soccer fitness.',
        skill: 'Fitness',
        subSkills: ['Speed', 'Endurance', 'Recovery'],
        difficulty: 'Intermediate',
        equipment: ['Cones', 'Stopwatch'],
        trainingStyle: 'high intensity',
        duration: 25,
        reps: 8,
        sets: 4,
        videoUrl: 'https://example.com/sprint-intervals',
        instructions: [
          'Set up 40-yard sprint markers',
          'Sprint at maximum effort for 30 seconds',
          'Rest for 60 seconds between sprints',
          'Complete 8 sprint intervals'
        ],
        tips: [
          'Focus on proper running form',
          'Use your arms for power',
          'Don\'t slow down at the end'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440017',
        title: 'Agility Ladder Workout',
        description: 'Improve footwork and coordination. Essential for quick movements on the field.',
        skill: 'Fitness',
        subSkills: ['Agility', 'Coordination', 'Quick Feet'],
        difficulty: 'Beginner',
        equipment: ['Agility Ladder', 'Cones'],
        trainingStyle: 'medium intensity',
        duration: 12,
        reps: 3,
        sets: 3,
        videoUrl: 'https://example.com/agility-ladder',
        instructions: [
          'Set up agility ladder on flat ground',
          'Practice different footwork patterns',
          'Start slowly and build up speed',
          'Complete 3 sets of each pattern'
        ],
        tips: [
          'Stay light on your feet',
          'Keep your head up',
          'Focus on speed and precision'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440018',
        title: 'Plyometric Power Training',
        description: 'Build explosive power for jumping and sprinting. Become more athletic.',
        skill: 'Fitness',
        subSkills: ['Power', 'Explosiveness', 'Jumping'],
        difficulty: 'Advanced',
        equipment: ['Cones', 'Markers'],
        trainingStyle: 'high intensity',
        duration: 20,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/plyometric-training',
        instructions: [
          'Set up stations for different plyometric exercises',
          'Include jump squats, box jumps, and bounds',
          'Focus on explosive movements',
          'Rest 2 minutes between sets'
        ],
        tips: [
          'Land softly to protect your joints',
          'Use your arms for momentum',
          'Focus on quality over quantity'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      // SPECIALIZED DRILLS
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440019',
        title: 'Goalkeeper Reaction Training',
        description: 'Improve reflexes and shot-stopping ability. Essential for goalkeepers.',
        skill: 'Goalkeeping',
        subSkills: ['Reactions', 'Diving', 'Positioning'],
        difficulty: 'Intermediate',
        equipment: ['Ball', 'Goal', 'Wall'],
        trainingStyle: 'low intensity',
        duration: 18,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/goalkeeper-reactions',
        instructions: [
          'Stand in goal and have balls thrown at you',
          'React quickly to save each shot',
          'Practice diving saves to both sides',
          'Focus on getting back to your feet quickly'
        ],
        tips: [
          'Stay alert and ready',
          'Use proper diving technique',
          'Keep your eyes on the ball'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440020',
        title: 'Set Piece Specialist',
        description: 'Master free kicks and corners. Become your team\'s dead ball specialist.',
        skill: 'Set Pieces',
        subSkills: ['Free Kicks', 'Corners', 'Technique'],
        difficulty: 'Advanced',
        equipment: ['Ball', 'Goal', 'Wall'],
        trainingStyle: 'low intensity',
        duration: 30,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/set-pieces',
        instructions: [
          'Practice free kicks from different angles',
          'Work on both power and placement',
          'Practice corner kicks with different techniques',
          'Set up targets in the goal'
        ],
        tips: [
          'Develop a consistent routine',
          'Pick your spot before you shoot',
          'Practice regularly to maintain accuracy'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      // ADDITIONAL ADVANCED DRILLS
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440021',
        title: 'Messi-Style Close Control',
        description: 'Master close control in tight spaces like Lionel Messi. Essential for creative players.',
        skill: 'Dribbling',
        subSkills: ['Close Control', 'Balance', 'Creativity'],
        difficulty: 'Advanced',
        equipment: ['Ball', 'Cones'],
        trainingStyle: 'low intensity',
        duration: 22,
        reps: 5,
        sets: 3,
        videoUrl: 'https://example.com/messi-control',
        instructions: [
          'Set up a tight 3x3 yard box',
          'Keep the ball moving with small touches',
          'Use all parts of your feet',
          'Stay within the box for 60 seconds'
        ],
        tips: [
          'Keep the ball glued to your feet',
          'Use your body to shield the ball',
          'Change direction frequently'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440022',
        title: 'Tiki-Taka Passing Precision',
        description: 'Master quick, short passes like Barcelona. Perfect for possession-based play.',
        skill: 'Passing',
        subSkills: ['Quick Passing', 'Accuracy', 'Movement'],
        difficulty: 'Intermediate',
        equipment: ['Ball', 'Cones', 'Wall'],
        trainingStyle: 'low intensity',
        duration: 20,
        reps: 50,
        sets: 2,
        videoUrl: 'https://example.com/tiki-taka',
        instructions: [
          'Set up 3 targets in a triangle formation',
          'Pass quickly between targets',
          'Use only 1-2 touches per pass',
          'Complete 50 successful sequences'
        ],
        tips: [
          'Keep your head up to see the next pass',
          'Use the inside of your foot for accuracy',
          'Move immediately after passing'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440023',
        title: 'Cristiano Power Headers',
        description: 'Develop heading power and accuracy like Cristiano Ronaldo. Dominate in the air.',
        skill: 'Heading',
        subSkills: ['Power', 'Accuracy', 'Timing'],
        difficulty: 'Intermediate',
        equipment: ['Ball', 'Goal', 'Partner'],
        trainingStyle: 'low intensity',
        duration: 16,
        reps: 10,
        sets: 3,
        videoUrl: 'https://example.com/power-headers',
        instructions: [
          'Have a partner throw balls for you to head',
          'Focus on timing your jump',
          'Use your forehead for power',
          'Aim for the corners of the goal'
        ],
        tips: [
          'Keep your eyes open when heading',
          'Use your whole body for power',
          'Attack the ball, don\'t wait for it'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440024',
        title: 'Neymar Skill Moves',
        description: 'Learn flashy skill moves to beat defenders. Add flair to your game.',
        skill: 'Dribbling',
        subSkills: ['Skill Moves', 'Creativity', 'Flair'],
        difficulty: 'Advanced',
        equipment: ['Ball', 'Cones'],
        trainingStyle: 'low intensity',
        duration: 25,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/neymar-skills',
        instructions: [
          'Practice step-overs, rainbow flicks, and elasticos',
          'Start slowly and build up speed',
          'Focus on selling the move with your body',
          'Use in small-sided games'
        ],
        tips: [
          'Practice both ways (left and right)',
          'Use skills sparingly in games',
          'Perfect the basics first'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440025',
        title: 'Goalkeeper Distribution',
        description: 'Improve goal kick and throwing accuracy. Start attacks from the back.',
        skill: 'Goalkeeping',
        subSkills: ['Distribution', 'Accuracy', 'Range'],
        difficulty: 'Intermediate',
        equipment: ['Ball', 'Targets', 'Goal'],
        trainingStyle: 'low intensity',
        duration: 18,
        reps: 5,
        sets: 4,
        videoUrl: 'https://example.com/goalkeeper-distribution',
        instructions: [
          'Set up targets at different distances',
          'Practice goal kicks to each target',
          'Work on both power and accuracy',
          'Include throwing practice'
        ],
        tips: [
          'Use proper kicking technique',
          'Follow through toward your target',
          'Practice with both feet'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      // TEAM PLAY DRILLS
      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440026',
        title: '2v1 Attacking Play',
        description: 'Master 2v1 situations in attack. Learn when to pass and when to shoot.',
        skill: 'Team Play',
        subSkills: ['Decision Making', 'Passing', 'Movement'],
        difficulty: 'Intermediate',
        equipment: ['Ball', 'Cones', 'Partners'],
        trainingStyle: 'low intensity',
        duration: 20,
        reps: 5,
        sets: 3,
        videoUrl: 'https://example.com/2v1-attack',
        instructions: [
          'Set up with 2 attackers and 1 defender',
          'Work the ball to create scoring opportunities',
          'Focus on quick passing and movement',
          'Switch roles every 5 minutes'
        ],
        tips: [
          'Communicate with your partner',
          'Look for the overlap',
          'Don\'t force the pass'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440027',
        title: 'Small-Sided Games',
        description: 'Play 3v3 or 4v4 games to improve all aspects of your game.',
        skill: 'Team Play',
        subSkills: ['All Skills', 'Decision Making', 'Fitness'],
        difficulty: 'All Levels',
        equipment: ['Ball', 'Cones', 'Partners'],
        trainingStyle: 'low intensity',
        duration: 30,
        reps: 5,
        sets: 3,
        videoUrl: 'https://example.com/small-sided-games',
        instructions: [
          'Set up small goals or targets',
          'Play short games (5-10 minutes)',
          'Focus on quick decision making',
          'Rotate players regularly'
        ],
        tips: [
          'Play with intensity',
          'Use all the skills you\'ve practiced',
          'Communicate constantly'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440028',
        title: 'Crossing and Finishing',
        description: 'Practice crossing from wide areas and finishing in the box.',
        skill: 'Crossing',
        subSkills: ['Crossing', 'Finishing', 'Timing'],
        difficulty: 'Intermediate',
        equipment: ['Ball', 'Goal', 'Cones'],
        trainingStyle: 'low intensity',
        duration: 22,
        reps: 5,
        sets: 3,
        videoUrl: 'https://example.com/crossing-finishing',
        instructions: [
          'Set up wide positions for crossing',
          'Practice different types of crosses',
          'Work on timing your runs into the box',
          'Focus on first-time finishes'
        ],
        tips: [
          'Get your head up before crossing',
          'Aim for the penalty spot',
          'Attack the ball when finishing'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440029',
        title: 'Defensive Pressing',
        description: 'Learn to press as a unit and win the ball back quickly.',
        skill: 'Defending',
        subSkills: ['Pressing', 'Teamwork', 'Intensity'],
        difficulty: 'Advanced',
        equipment: ['Ball', 'Cones', 'Partners'],
        trainingStyle: 'low intensity',
        duration: 18,
        reps: 5,
        sets: 3,
        videoUrl: 'https://example.com/defensive-pressing',
        instructions: [
          'Work in groups of 3-4 players',
          'Press together as a unit',
          'Cut off passing lanes',
          'Win the ball back quickly'
        ],
        tips: [
          'Communicate constantly',
          'Press with intensity',
          'Don\'t leave gaps'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),

      DrillModel(
        id: '550e8400-e29b-41d4-a716-446655440030',
        title: 'Mental Toughness Training',
        description: 'Build mental resilience and concentration. Essential for high-pressure situations.',
        skill: 'Mental',
        subSkills: ['Concentration', 'Resilience', 'Focus'],
        difficulty: 'All Levels',
        equipment: ['Ball', 'Cones'],
        trainingStyle: 'low intensity',
        duration: 15,
        reps: 5,
        sets: 3,
        videoUrl: 'https://example.com/mental-training',
        instructions: [
          'Practice skills while under pressure',
          'Set challenging targets to achieve',
          'Focus on maintaining quality when tired',
          'Use visualization techniques'
        ],
        tips: [
          'Stay positive when things go wrong',
          'Focus on the process, not the outcome',
          'Breathe deeply to stay calm'
        ],
        isCustom: false, // ✅ ADDED: Set isCustom to false for test drills
      ),
    ];
  }

  /// Get all test drills (public access to expanded drills)
  static List<DrillModel> getTestDrills() {
    return _getExpandedTestDrills();
  }

  /// Simulate realistic API search with pagination
  static Future<PaginatedDrillResponse> searchDrills(DrillSearchFilters filters) async {
    debugLog('Searching drills with filters: page=${filters.page}, pageSize=${filters.pageSize}');
    
    // Simulate API delay
    await simulateApiDelay(null, 
      milliseconds: _minApiDelayMs + Random().nextInt(_maxApiDelayMs - _minApiDelayMs));

    final allDrills = _getExpandedTestDrills();
    List<DrillModel> filteredDrills = List.from(allDrills);

    // Apply filters
    if (filters.query != null && filters.query!.isNotEmpty) {
      final query = filters.query!.toLowerCase();
      filteredDrills = filteredDrills.where((drill) {
        return drill.title.toLowerCase().contains(query) ||
               drill.description.toLowerCase().contains(query) ||
               drill.skill.toLowerCase().contains(query) ||
               drill.subSkills.any((skill) => skill.toLowerCase().contains(query));
      }).toList();
    }

    if (filters.skill != null) {
      filteredDrills = filteredDrills.where((drill) {
        return drill.skill.toLowerCase() == filters.skill!.toLowerCase() ||
               drill.subSkills.any((skill) => skill.toLowerCase().contains(filters.skill!.toLowerCase()));
      }).toList();
    }

    if (filters.difficulty != null) {
      filteredDrills = filteredDrills.where((drill) {
        return drill.difficulty.toLowerCase() == filters.difficulty!.toLowerCase();
      }).toList();
    }

    if (filters.trainingStyle != null) {
      filteredDrills = filteredDrills.where((drill) {
        return drill.trainingStyle.toLowerCase().contains(filters.trainingStyle!.toLowerCase());
      }).toList();
    }

    if (filters.equipment != null && filters.equipment!.isNotEmpty) {
      filteredDrills = filteredDrills.where((drill) {
        return filters.equipment!.any((equipment) => 
          drill.equipment.any((drillEquipment) => 
            drillEquipment.toLowerCase().contains(equipment.toLowerCase())));
      }).toList();
    }

    if (filters.maxDuration != null) {
      filteredDrills = filteredDrills.where((drill) {
        return drill.duration <= filters.maxDuration!;
      }).toList();
    }

    // Apply pagination
    final totalCount = filteredDrills.length;
    final pageSize = filters.pageSize.clamp(1, _maxPageSize);
    final totalPages = (totalCount / pageSize).ceil();
    final currentPage = filters.page.clamp(1, totalPages.clamp(1, double.infinity).toInt());
    
    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);
    
    final paginatedDrills = filteredDrills.sublist(
      startIndex, 
      endIndex
    );

    debugLog('Search results: ${paginatedDrills.length} drills on page $currentPage of $totalPages');

    return PaginatedDrillResponse(
      drills: paginatedDrills,
      totalCount: totalCount,
      currentPage: currentPage,
      pageSize: pageSize,
      totalPages: totalPages,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
    );
  }

  /// Get test session drills with realistic progression
  static List<EditableDrillModel> getTestSessionDrills() {
    final allDrills = _getExpandedTestDrills();
    final sessionDrills = allDrills.take(3).toList();
    
    return sessionDrills.map((drill) {
      // Vary the sets/reps based on drill type
      int sets = 3;
      int reps = 10;
      
      switch (drill.skill.toLowerCase()) {
        case 'fitness':
          sets = 4;
          reps = 8;
          break;
        case 'shooting':
          sets = 3;
          reps = 6;
          break;
        case 'dribbling':
          sets = 2;
          reps = 12;
          break;
        default:
          sets = 3;
          reps = 10;
      }
      
      return EditableDrillModel(
        drill: drill,
        totalSets: sets,
        totalReps: reps,
        totalDuration: drill.duration,
        setsDone: 0,
        isCompleted: false,
      );
    }).toList();
  }

  /// Get realistic user progress data
  static Future<Map<String, dynamic>> getTestUserProgress() async {
    await simulateApiDelay(null, milliseconds: 500);
    
    return {
      'weeklyProgress': {
        'Monday': Random().nextInt(4),
        'Tuesday': Random().nextInt(4),
        'Wednesday': Random().nextInt(4),
        'Thursday': Random().nextInt(4),
        'Friday': Random().nextInt(4),
        'Saturday': Random().nextInt(4),
        'Sunday': Random().nextInt(4),
      },
      'skillProgress': {
        'Dribbling': 0.65 + Random().nextDouble() * 0.3,
        'Passing': 0.55 + Random().nextDouble() * 0.35,
        'Shooting': 0.45 + Random().nextDouble() * 0.4,
        'First Touch': 0.35 + Random().nextDouble() * 0.45,
        'Defending': 0.25 + Random().nextDouble() * 0.5,
        'Goalkeeping': 0.20 + Random().nextDouble() * 0.55,
        'Fitness': 0.30 + Random().nextDouble() * 0.5,
      },
      'totalSessions': 12 + Random().nextInt(20),
      'totalDrills': 45 + Random().nextInt(50),
      'currentStreak': Random().nextInt(7),
      'averageSessionTime': 25 + Random().nextInt(20),
    };
  }

  /// Get drill recommendations based on user progress
  static Future<List<DrillModel>> getRecommendedDrills(int count) async {
    await simulateApiDelay(null, milliseconds: 800);
    
    final allDrills = _getExpandedTestDrills();
    allDrills.shuffle();
    
    return allDrills.take(count).toList();
  }

  /// Simulate API delay with realistic timing
  static Future<T> simulateApiDelay<T>(T? data, {int milliseconds = 1000}) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
    return data as T;
  }

  /// Debug logging for development
  static void debugLog(String message) {
    if (AppConfig.logApiCalls) {
      print('🔍 [TestDataAPI] $message');
    }
  }

  /// Get popular drills (most commonly used)
  static Future<List<DrillModel>> getPopularDrills() async {
    await simulateApiDelay(null, milliseconds: 600);
    
    final allDrills = _getExpandedTestDrills();
    final popularDrills = [
      allDrills[0],  // Cone Weaving
      allDrills[3],  // Precision Passing
      allDrills[6],  // Power Shot
      allDrills[9],  // Wall Control
      allDrills[15], // Sprint Training
    ];
    
    return popularDrills;
  }

  /// Get drills by skill category
  static Future<List<DrillModel>> getDrillsBySkill(String skill) async {
    await simulateApiDelay(null, milliseconds: 400);
    
    final allDrills = _getExpandedTestDrills();
    return allDrills.where((drill) => 
      drill.skill.toLowerCase() == skill.toLowerCase()
    ).toList();
  }

  /// Get available skills/categories
  static List<String> getAvailableSkills() {
    return [
      'Passing', 
      'Shooting',
      'Dribbling',
      'First Touch',
      'Defending',
      'Goalkeeping',
      'Fitness',
    ];
  }

  /// Get available difficulty levels
  static List<String> getAvailableDifficulties() {
    return ['Beginner', 'Intermediate', 'Advanced', 'All Levels'];
  }

  /// Get available training styles
  static List<String> getAvailableTrainingStyles() {
    return ['Individual', 'Partner', 'Small Group', 'Team'];
  }

  /// Simulate error for testing error handling
  static Future<T> simulateError<T>(String errorMessage) async {
    await simulateApiDelay(null, milliseconds: 2000);
    throw Exception(errorMessage);
  }
} 