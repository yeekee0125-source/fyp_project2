import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final String title;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Use .networkUrl with specific hardware-friendly options
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      // This helps bypass some hardware decoder resource limits on physical phones
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _hasError = false; // Reset error if initialization finally works
        });
        _controller.play();
        _controller.setLooping(true); // Optional: keep it playing for tutorials
      }
    }).catchError((error) {
      debugPrint("Video Player Error: $error");
      if (mounted) {
        setState(() => _hasError = true);
      }
    });

    // Listen for changes (like buffering or completion)
    _controller.addListener(() {
      if (_controller.value.hasError && mounted) {
        setState(() => _hasError = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Show Thumbnail while loading or if error occurs
            if (!_controller.value.isInitialized || _hasError)
              Image.network(
                widget.thumbnailUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (context, e, s) => const Icon(Icons.movie, color: Colors.white, size: 50),
              ),

            // 2. Video Player
            if (_controller.value.isInitialized)
              GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),

            // 3. Controls Overlay
            if (_controller.value.isInitialized && _showControls)
              _buildControls(),

            // 4. Loading Spinner (Only show if not initialized and no error)
            if (!_controller.value.isInitialized && !_hasError)
              const CircularProgressIndicator(color: Colors.orange),

            // 5. Error Message
            if (_hasError)
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 50),
                  SizedBox(height: 10),
                  Text("Hardware Decoder Error", style: TextStyle(color: Colors.white)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: Colors.white,
              size: 70,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(playedColor: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}