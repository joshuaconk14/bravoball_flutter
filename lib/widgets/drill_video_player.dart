import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io'; // Add this import for File support

class DrillVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  final bool showControls;

  const DrillVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.showControls = true,
  });

  @override
  State<DrillVideoPlayer> createState() => _DrillVideoPlayerState();
}

class _DrillVideoPlayerState extends State<DrillVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Check if URL is valid
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
        });
        return;
      }

      // Initialize controller based on URL type
      if (widget.videoUrl.startsWith('http')) {
        // Network URL - existing functionality
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else if (widget.videoUrl.startsWith('/') || widget.videoUrl.contains('\\')) {
        // Local file path - new functionality for custom drills
        final file = File(widget.videoUrl);
        if (await file.exists()) {
          _controller = VideoPlayerController.file(file);
        } else {
          setState(() {
            _hasError = true;
          });
          return;
        }
      } else {
        // Asset file - existing functionality
        _controller = VideoPlayerController.asset(widget.videoUrl);
      }

      // Initialize the controller
      await _controller.initialize();

      // Configure for looping and no audio
      _controller.setLooping(true);
      _controller.setVolume(0.0); // Mute audio
      
      // Auto-play the video
      _controller.play();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || widget.videoUrl.isEmpty) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              VideoPlayer(_controller),
              if (widget.showControls) _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade300,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade300,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'No video for this drill right now',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.black26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(_controller.value.position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 