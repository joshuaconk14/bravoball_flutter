import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:ui';
import 'package:rive/rive.dart' as rive;
import '../constants/app_theme.dart';

class DrillVideoBackground extends StatefulWidget {
  final String videoUrl;
  final Widget child; // The content to overlay on top of the video
  final VoidCallback? onTap; // Optional tap handler for hide/show UI

  const DrillVideoBackground({
    Key? key,
    required this.videoUrl,
    required this.child,
    this.onTap,
  });

  @override
  State<DrillVideoBackground> createState() => _DrillVideoBackgroundState();
}

class _DrillVideoBackgroundState extends State<DrillVideoBackground> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideo = false;
  bool _isVideoLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isNotEmpty) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DrillVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the video URL has changed
    if (widget.videoUrl != oldWidget.videoUrl) {
      if (kDebugMode) {
        if (kDebugMode) print('🔄 Video URL changed from "${oldWidget.videoUrl}" to "${widget.videoUrl}"');
      }
      
      // Dispose old controller and reinitialize with new URL
      _videoController?.dispose();
      _videoController = null;
      
      // Reset state
      setState(() {
        _isVideoInitialized = false;
        _hasVideo = false;
        _isVideoLoading = false;
      });
      
      // Initialize with new URL if not empty
      if (widget.videoUrl.isNotEmpty) {
        _initializeVideo();
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoUrl.isEmpty) return;
      
      setState(() {
        _isVideoLoading = true;
      });
      
      // Detect video URL type and use appropriate controller
      if (widget.videoUrl.startsWith('http')) {
        // Network URL
        final videoUrl = Uri.parse(widget.videoUrl);
        _videoController = VideoPlayerController.networkUrl(videoUrl);
      } else if (widget.videoUrl.startsWith('/') || widget.videoUrl.contains('\\')) {
        // Local file path
        final file = File(widget.videoUrl);
        if (await file.exists()) {
          _videoController = VideoPlayerController.file(file);
          if (kDebugMode) {
            if (kDebugMode) print('🎬 Loading local video file: ${widget.videoUrl}');
          }
        } else {
          if (kDebugMode) {
            if (kDebugMode) print('🎬 Local video file does not exist: ${widget.videoUrl}');
          }
          setState(() {
            _hasVideo = false;
            _isVideoLoading = false;
          });
          return;
        }
      } else {
        // Asset file
        _videoController = VideoPlayerController.asset(widget.videoUrl);
      }
      
      await _videoController!.initialize();
      
      // Configure the controller
      await Future.wait([
        _videoController!.setLooping(true),
        _videoController!.setVolume(0.0),
      ]);
      
      // Start playing the video
      await _videoController!.play();
      
      setState(() {
        _isVideoInitialized = true;
        _hasVideo = true;
        _isVideoLoading = false;
      });
      
      if (kDebugMode) {
        if (kDebugMode) print('✅ Video background initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Video background initialization error: $e');
      }
      setState(() {
        _hasVideo = false;
        _isVideoLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            // Background layer
            _buildBackground(),
            
            // Content overlay
            widget.child,
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (_isVideoLoading) {
      return _buildVideoLoadingState();
    } else if (_hasVideo && _isVideoInitialized && _videoController != null) {
      return _buildVideoBackground();
    } else {
      return _buildNoVideoBackground();
    }
  }

  Widget _buildVideoLoadingState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading drill video...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we prepare your training',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Stack(
      children: [
        // Blurred background video (full screen) - fills entire screen
        Positioned.fill(
          child: ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: FittedBox(
                fit: BoxFit.cover, // Fills entire screen for background
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          ),
        ),
        
        // ✅ FIXED: Sharp foreground video - centered, maintains aspect ratio
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
      ],
    );
  }

  Widget _buildNoVideoBackground() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'No drill video yet!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              child: const rive.RiveAnimation.asset(
                'assets/rive/Bravo_Animation.riv',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }} 