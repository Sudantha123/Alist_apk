import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;

  bool _showControls = true;
  bool _isFullscreen = false;
  double _volume = 100;
  double _brightness = 1.0;
  bool _showVolumeSlider = false;
  bool _showBrightnessSlider = false;

  late AnimationController _controlsAnimController;
  late Animation<double> _controlsAnimation;

  @override
  void initState() {
    super.initState();
    _controlsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimController,
      curve: Curves.easeInOut,
    );
    _controlsAnimController.forward();

    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 64 * 1024 * 1024, // 64MB buffer for smooth playback
        title: 'AList Player',
      ),
    );
    _controller = VideoController(_player);

    _player.open(Media(widget.url));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _player.state.playing) {
        setState(() => _showControls = false);
        _controlsAnimController.reverse();
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsAnimController.forward();
      _startHideControlsTimer();
    } else {
      _controlsAnimController.reverse();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _controlsAnimController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width / 2) {
            _player.seek(
              (_player.state.position - const Duration(seconds: 10))
                  .clamp(Duration.zero, _player.state.duration),
            );
          } else {
            _player.seek(
              (_player.state.position + const Duration(seconds: 10))
                  .clamp(Duration.zero, _player.state.duration),
            );
          }
        },
        child: Stack(
          children: [
            // Video
            Center(
              child: Video(
                controller: _controller,
                controls: NoVideoControls,
              ),
            ),

            // Controls overlay
            FadeTransition(
              opacity: _controlsAnimation,
              child: _showControls ? _buildControls() : const SizedBox.shrink(),
            ),

            // Volume slider overlay
            if (_showVolumeSlider) _buildVolumeOverlay(),
            if (_showBrightnessSlider) _buildBrightnessOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000),
            Colors.transparent,
            Colors.transparent,
            Color(0xCC000000),
          ],
          stops: [0, 0.25, 0.75, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const Spacer(),
            _buildCenterControls(),
            const Spacer(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
            onPressed: () => setState(() {
              _showVolumeSlider = !_showVolumeSlider;
              _showBrightnessSlider = false;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6_rounded, color: Colors.white),
            onPressed: () => setState(() {
              _showBrightnessSlider = !_showBrightnessSlider;
              _showVolumeSlider = false;
            }),
          ),
          IconButton(
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _isFullscreen = !_isFullscreen);
              SystemChrome.setPreferredOrientations(
                _isFullscreen
                    ? [DeviceOrientation.portraitUp]
                    : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return StreamBuilder<bool>(
      stream: _player.stream.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              Icons.replay_10_rounded,
              () => _player.seek(
                (_player.state.position - const Duration(seconds: 10))
                    .clamp(Duration.zero, _player.state.duration),
              ),
              size: 36,
            ),
            const SizedBox(width: 24),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: _player.playOrPause,
              ),
            ),
            const SizedBox(width: 24),
            _buildControlButton(
              Icons.forward_10_rounded,
              () => _player.seek(
                (_player.state.position + const Duration(seconds: 10))
                    .clamp(Duration.zero, _player.state.duration),
              ),
              size: 36,
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap, {double size = 28}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: _player.stream.position,
            builder: (context, posSnap) {
              return StreamBuilder<Duration>(
                stream: _player.stream.duration,
                builder: (context, durSnap) {
                  final position = posSnap.data ?? Duration.zero;
                  final duration = durSnap.data ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                          thumbColor: Colors.white,
                          overlayColor: AppTheme.primary.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (v) {
                            final newPos = Duration(
                              milliseconds: (v * duration.inMilliseconds).round(),
                            );
                            _player.seek(newPos);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          // Speed selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              return StreamBuilder<double>(
                stream: _player.stream.rate,
                builder: (context, snapshot) {
                  final currentRate = snapshot.data ?? 1.0;
                  final isSelected = (currentRate - speed).abs() < 0.01;
                  return GestureDetector(
                    onTap: () => _player.setRate(speed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeOverlay() {
    return Positioned(
      right: 16,
      top: 80,
      bottom: 120,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: _volume,
                  min: 0,
                  max: 100,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    _player.setVolume(v);
                  },
                  activeColor: AppTheme.primary,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
            Text(
              '${_volume.round()}%',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessOverlay() {
    return Positioned(
      left: 16,
      top: 80,
      bottom: 120,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(Icons.brightness_6_rounded, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: _brightness,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) {
                    setState(() => _brightness = v);
                    // screen_brightness package needed for actual brightness control
                  },
                  activeColor: const Color(0xFFFFD54F),
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
            Text(
              '${(_brightness * 100).round()}%',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
