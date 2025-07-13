# Background Timer Setup Guide

## Overview
This implementation allows drill timers to continue running even when the phone screen is off, using a combination of:
1. **Background Audio Session** - Silent audio keeps app active
2. **Wake Lock** - Prevents screen sleep during workouts  
3. **Local Notifications** - Alerts when timer completes
4. **Enhanced Audio Cues** - Countdown and completion sounds

## Required Files to Add

### 1. Silent Audio File
Create a silent audio file for background playback:

**Option A: Generate programmatically (Recommended)**
```bash
# Using ffmpeg (install via brew install ffmpeg on Mac)
ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 10 -acodec mp3 assets/audio/silent-timer.mp3
```

**Option B: Manual creation**
1. Open any audio editing software (Audacity, GarageBand, etc.)
2. Generate 10 seconds of silence
3. Export as MP3 at 44.1kHz sample rate
4. Keep file size minimal (should be ~3KB)
5. Save as `assets/audio/silent-timer.mp3`

### 2. Platform Permissions (Already Added)

**iOS (Info.plist)**
- ✅ Background audio capability
- ✅ Audio session permissions

**Android (AndroidManifest.xml)**  
- ✅ Wake lock permissions
- ✅ Foreground service permissions

## Implementation Details

### BackgroundTimerService Features
- **Silent Background Audio**: Keeps app active when screen is off
- **Timer Continuity**: Drill timers continue running in background
- **Audio Cues**: Countdown and completion sounds work in background
- **Haptic Feedback**: Vibration cues at important moments
- **Debug Mode**: Faster timers for testing

### Wake Lock Integration
- **Auto-Enable**: Activates when drill timer starts
- **Auto-Disable**: Deactivates when drill completes/stops
- **Battery Efficient**: Only active during actual workout time

### Notification Support (Optional)
- **Timer Alerts**: Notify when timer completes in background
- **Drill Progress**: Show which set/drill is active
- **Sound & Vibration**: Platform-native alert experience

## Testing the Implementation

### 1. Basic Functionality Test
```dart
// Test in drill follow along view
1. Start a drill timer
2. Lock phone screen immediately  
3. Wait for countdown audio to play
4. Timer should continue running
5. Completion audio should play when done
```

### 2. Background Audio Test
```dart
// Verify background session
1. Start timer
2. Switch to another app
3. Timer continues running
4. Audio cues still play
5. Return to app - timer still active
```

### 3. Debug Mode Test
```dart
// Fast testing (AppConfig.debug = true)
1. Timer runs 10x faster for testing
2. Background audio still maintained
3. All cues still trigger correctly
```

## Usage in DrillFollowAlongView

### Before (Basic Timer)
```dart
Timer.periodic(Duration(seconds: 1), (timer) {
  // Timer stops when app backgrounded
});
```

### After (Background Timer)
```dart
BackgroundTimerService.shared.startTimer(
  durationSeconds: duration,
  onTick: (remaining) => updateUI(remaining),
  onComplete: () => moveToNextSet(),
);
// Timer continues in background!
```

## Troubleshooting

### Audio Not Playing in Background
1. Check iOS Background App Refresh is enabled
2. Verify audio files exist in assets folder
3. Ensure device is not in silent mode for audio cues
4. Check app permissions for audio playback

### Timer Stops in Background
1. Verify silent-timer.mp3 file exists and is valid
2. Check platform permissions are correctly set
3. Test with device plugged in (some devices optimize differently)
4. Ensure background audio session starts before timer

### Wake Lock Issues
1. Check Android wake lock permissions
2. Verify WakeLockService.enableWakeLock() is called
3. Test on physical device (simulator behavior differs)

## Battery Impact

### Optimized Approach
- **Silent Audio**: Minimal battery usage (~1-2% for 30min workout)
- **Wake Lock**: Only active during timer periods
- **Smart Cleanup**: All background processes stop when drill ends

### Best Practices
- Wake lock automatically disabled after workout
- Background audio session ends with timer
- No persistent background processes
- Efficient timer intervals (1 second, not milliseconds)

## Alternative Approaches Considered

### 1. True Background Service
- **Pros**: More reliable background execution
- **Cons**: Complex setup, battery drain, platform restrictions
- **Verdict**: Overkill for simple timer use case

### 2. Local Notifications Only
- **Pros**: Simple implementation, no background execution
- **Cons**: No continuous timer, only end-of-timer alerts
- **Verdict**: Good complement but not sufficient alone

### 3. Keep Screen On Only
- **Pros**: Very simple, reliable
- **Cons**: Battery drain, not true background functionality  
- **Verdict**: Good fallback, included as backup approach

## Future Enhancements

### Possible Additions
1. **Progress Notifications**: Show timer progress in notification
2. **Voice Cues**: Spoken countdown and instructions
3. **Music Integration**: Play workout music with timer cues
4. **Apple Watch Support**: Timer display on watch
5. **Background Analytics**: Track workout timing patterns

### Implementation Priority
1. ✅ Silent audio background (Phase 1)
2. ✅ Wake lock support (Phase 1) 
3. 🔄 Local notifications (Phase 2)
4. 🔄 Voice cues (Phase 3)
5. 🔄 Music integration (Phase 4) 