# Testing Background Timer Functionality

## 🎯 Quick Answer: Testing Devices

### ✅ **Best Testing Experience**
- **Physical iPhone/Android Device** - Full background functionality works
- **Connected via USB or wireless debugging** - Both work perfectly

### ⚠️ **Limited Testing (iOS Simulator)**
- **Background audio** - Works but limited
- **Timer continuity** - Partially works
- **Wake lock** - Not available on simulator
- **Recommendation**: Use for UI testing only

### ❌ **Won't Work**
- **Browser/Web** - No background audio support
- **Desktop simulators** - No mobile background features

## 🚀 Setup Steps (Required Before Testing)

### 1. Install Dependencies
```bash
cd bravoball_flutter
flutter pub get
```

### 2. Create Silent Audio File
**Using ffmpeg (Mac/Linux):**
```bash
# Install ffmpeg if needed
brew install ffmpeg  # Mac
# or
apt-get install ffmpeg  # Linux

# Generate 10-second silent audio file
ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 10 -acodec mp3 assets/audio/silent-timer.mp3
```

**Manual Alternative:**
1. Download any 10-second silent MP3 file
2. Save as `assets/audio/silent-timer.mp3`
3. Ensure file size is small (~3KB)

### 3. Verify Assets
Check that these files exist:
- ✅ `assets/audio/321-start.MP3`
- ✅ `assets/audio/321-done.MP3` 
- ✅ `assets/audio/success.MP3`
- ✅ `assets/audio/silent-timer.mp3` ← **New file needed**

## 📱 Testing on Physical Device (Recommended)

### **iPhone Testing**
```bash
# Connect iPhone via USB or ensure wireless debugging is enabled
flutter run

# Or for wireless iPhone:
flutter run --device-id=your-wireless-iphone-id
```

### **Android Testing**
```bash
# Connect Android via USB or WiFi ADB
flutter run

# Or for wireless Android:
flutter run --device-id=your-wireless-android-id
```

## 🧪 Test Scenarios

### **Test 1: Basic Background Functionality**
1. **Start App** → Go to drill follow along
2. **Start Timer** → Press play button
3. **Lock Phone** → Immediately lock screen
4. **Wait** → Should hear countdown audio through phone speakers
5. **Verify** → Timer continues running (unlock to check)
6. **Complete** → Should hear completion sound

**Expected Results:**
- ✅ Countdown audio plays when screen locked
- ✅ Timer continues running in background
- ✅ Completion audio plays when timer ends
- ✅ App shows correct time when unlocked

### **Test 2: App Switching**
1. **Start Timer** → Begin drill timer
2. **Switch Apps** → Open another app (Messages, Safari, etc.)
3. **Wait** → Timer should continue running
4. **Return** → Come back to BravoBall app
5. **Verify** → Timer still running with correct time

**Expected Results:**
- ✅ Timer continues when app is backgrounded
- ✅ Audio cues still play from background
- ✅ Correct timer state when returning

### **Test 3: Debug Mode (Fast Testing)**
1. **Enable Debug** → Set `AppConfig.debug = true`
2. **Start Timer** → Timer runs 10x faster
3. **Lock Phone** → Test background immediately
4. **Verify** → Fast timer still works in background

**Expected Results:**
- ✅ Timer counts down every 100ms instead of 1s
- ✅ Background functionality still works
- ✅ All audio cues still trigger correctly

### **Test 4: Multiple Drill Sets**
1. **Start Multi-Set Drill** → Choose drill with 3+ sets
2. **Complete Set 1** → Let timer run to completion
3. **Lock Phone** → Lock during Set 2
4. **Verify** → Set 2 continues running
5. **Complete** → Finish all sets in background

**Expected Results:**
- ✅ Each set timer works in background
- ✅ Progress correctly tracked
- ✅ Completion sounds for each set

## 📊 Debugging Background Issues

### **Audio Not Playing in Background**
```dart
// Check these in your Flutter debug console:
🎵 Background timer session initialized  // Should see on start
🎵 Background audio started for timer    // Should see when timer starts
⏱️ Starting background countdown: 3      // Should see during countdown
🎯 Starting background timer: 300s       // Should see when timer starts
```

**Fixes:**
- Ensure `silent-timer.mp3` exists in assets
- Check device is not in Do Not Disturb mode
- Verify Background App Refresh is enabled (iOS)
- Test with volume up and device unmuted

### **Timer Stops in Background**
**Check Debug Console:**
```dart
❌ Error starting background audio: [error message]
🛑 Timer stopped, background session ended
```

**Fixes:**
- Verify audio file is valid MP3 format
- Check iOS Background Modes are properly set
- Test on physical device (not simulator)
- Ensure app has microphone/audio permissions

### **Wake Lock Issues**
```dart
🔆 Wake lock enabled - screen will stay on    // Should see on timer start
🌙 Wake lock disabled - screen can sleep normally  // Should see on timer end
```

**Fixes:**
- Only works on physical devices
- Check Android wake lock permissions
- Verify `WakeLockService.enableWakeLock()` is called

## 🔧 Platform-Specific Testing

### **iOS Testing Notes**
- **Background App Refresh**: Must be enabled for app
- **Silent Mode**: Audio cues respect silent switch
- **Background Audio**: Works best when music permissions are granted
- **Battery Optimization**: iOS manages background apps automatically

### **Android Testing Notes**
- **Battery Optimization**: Disable for BravoBall in device settings
- **Do Not Disturb**: May affect audio cues
- **Background App Limits**: Some Android ROMs have aggressive limits
- **Wake Lock**: More reliable than iOS for keeping screen awake

## 📈 Performance Monitoring

### **Battery Usage (Expected)**
- **30-minute workout**: ~1-2% additional battery drain
- **Silent audio playback**: Minimal CPU usage
- **Wake lock**: Only active during timer periods
- **Background processing**: Efficient 1-second intervals

### **Memory Usage**
- **Background timer service**: <1MB additional RAM
- **Audio players**: ~2-3MB during active timers
- **Clean shutdown**: All resources released when timer ends

## 🎛️ Advanced Testing

### **Test Background Audio Session**
```dart
// Add this to BackgroundTimerService for detailed logging
print('🎵 Audio session state: ${_isBackgroundSessionActive}');
print('⏱️ Timer running: ${_isTimerRunning}');
print('🔈 Audio player state: ${_backgroundPlayer.state}');
```

### **Test Network Interruption**
1. Start timer in background
2. Turn off WiFi/cellular
3. Timer should continue (no network needed)
4. Turn network back on
5. Verify app syncs properly when returning

### **Test Phone Calls**
1. Start drill timer
2. Receive/make phone call
3. Timer should pause during call
4. Resume after call ends
5. Verify timer state is preserved

## 🔍 Troubleshooting Common Issues

### **"Background audio not working on simulator"**
- ✅ **Expected behavior** - Use physical device for full testing
- 🔧 **Workaround** - Test UI and basic timer logic on simulator

### **"Timer stops when phone locked"**
- ❌ **Missing silent audio file** - Check `assets/audio/silent-timer.mp3` exists
- ❌ **Permissions** - Verify background audio permissions in Info.plist
- ❌ **Device settings** - Check Background App Refresh is enabled

### **"Audio cues not playing"**
- 🔇 **Silent mode** - Check device ringer switch
- 🔇 **Volume** - Ensure media volume is up
- 🔇 **Do Not Disturb** - Disable DND mode temporarily

### **"App crashes on background"**
- 💥 **Memory pressure** - iOS may kill app under memory pressure
- 💥 **Invalid audio file** - Verify silent-timer.mp3 is valid
- 💥 **Plugin compatibility** - Check audioplayers version compatibility

## ✅ Success Criteria

Your background timer is working correctly when:

1. **🔊 Audio Continuity**: Countdown and completion sounds play even when phone is locked
2. **⏰ Timer Persistence**: Timer continues counting down in background
3. **🔄 State Recovery**: Correct timer state when returning to app
4. **🔋 Battery Efficiency**: Minimal battery impact during workouts
5. **📱 Cross-Platform**: Works on both iOS and Android physical devices

## 🎯 Ready to Test!

**Quick Start:**
1. Run `flutter pub get`
2. Add `silent-timer.mp3` to assets
3. Deploy to physical device
4. Start a drill timer
5. Lock phone immediately
6. Listen for countdown audio
7. Unlock after 30 seconds to verify timer continued

**Need Help?** Check the debug console for detailed logging of all background timer operations! 