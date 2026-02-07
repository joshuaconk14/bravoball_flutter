/// App Asset Paths
/// 
/// Centralized single source of truth for all asset paths in the app.
/// This ensures consistency and makes it easy to update asset paths.
class AppAssets {
  // Private constructor to prevent instantiation
  AppAssets._();

  // MARK: - Icon Assets

  /// Treat icon asset path
  static const String treatIcon = 'assets/other-icons/Bravo_treat.png';

  // MARK: - Drill Skill Icons

  /// Base path for drill skill icons
  static const String _drillIconsBase = 'assets/drill-icons/';

  /// Get drill skill icon path by skill name
  /// 
  /// Normalizes skill names and returns the appropriate icon path.
  /// Falls back to dribbling icon if skill not found.
  static String getSkillIconPath(String skill) {
    // Normalize the skill name for better matching
    final normalizedSkill = skill.toLowerCase().replaceAll('_', ' ').trim();
    
    switch (normalizedSkill) {
      case 'passing':
        return '${_drillIconsBase}Player_Passing.png';
      case 'shooting':
        return '${_drillIconsBase}Player_Shooting.png';
      case 'dribbling':
        return '${_drillIconsBase}Player_Dribbling.png';
      case 'first touch':
      case 'firsttouch':
        return '${_drillIconsBase}Player_First_Touch.png';
      case 'defending':
        return '${_drillIconsBase}Player_Defending.png';
      case 'goalkeeping':
        return '${_drillIconsBase}Player_Goalkeeping.png';
      case 'fitness':
        return '${_drillIconsBase}Player_Fitness.png';
      default:
        return '${_drillIconsBase}Player_Dribbling.png'; // Fallback to dribbling icon
    }
  }

  // MARK: - Rive Animation Assets

  /// Base path for Rive animations
  static const String _riveBase = 'assets/rive/';

  static const String bravoAnimation = '${_riveBase}Bravo_Animation.riv';
  static const String bravoBallIntro = '${_riveBase}BravoBall_Intro.riv';
  static const String backpack = '${_riveBase}Backpack.riv';
  static const String grassField = '${_riveBase}Grass_Field.riv';
  static const String tabHouse = '${_riveBase}Tab_House.riv';
  static const String tabCalendar = '${_riveBase}Tab_Calendar.riv';
  static const String tabSaved = '${_riveBase}Tab_Saved.riv';
  static const String tabDude = '${_riveBase}Tab_Dude.riv';

  // MARK: - Audio Assets

  /// Base path for audio files (relative to assets folder, for use with AssetSource)
  static const String _audioBase = 'audio/';

  /// Audio file paths for use with AssetSource (relative to assets folder)
  static const String audio321Start = '${_audioBase}321-start.mp3';
  static const String audio321Done = '${_audioBase}321-done.mp3';
  static const String audioSuccess = '${_audioBase}success.mp3';
  static const String audioSilentTimer = '${_audioBase}silent-timer.mp3';
}

