import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isMuted = false;
  
  // Getter for mute status
  static bool get isMuted => _isMuted;
  
  // Toggle mute status
  static void toggleMute() {
    _isMuted = !_isMuted;
  }
  
  // Set mute status
  static void setMuted(bool muted) {
    _isMuted = muted;
  }
  
  /// Play countdown sound when user presses play button (3-2-1 countdown)
  static Future<void> playCountdownStart() async {
    if (_isMuted) return;
    
    try {
      await _player.play(AssetSource('audio/321-start.mp3'));
    } catch (e) {
      print('Error playing countdown start sound: $e');
    }
  }
  
  /// Play final countdown sound for last 3 seconds of drill timer
  static Future<void> playCountdownFinal() async {
    if (_isMuted) return;
    
    try {
      await _player.play(AssetSource('audio/321-done.mp3'));
    } catch (e) {
      print('Error playing final countdown sound: $e');
    }
  }
  

  /// Play success sound when trophy is tapped or drill/session completed
  static Future<void> playSuccess() async {
    if (_isMuted) return;
    
    try {
      await _player.play(AssetSource('audio/success.mp3'));
    } catch (e) {
      print('Error playing success sound: $e');
    }
  }
  
  /// Stop any currently playing audio
  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }
  
  /// Dispose of the audio player when app is closing
  static Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      print('Error disposing audio player: $e');
    }
  }
} 