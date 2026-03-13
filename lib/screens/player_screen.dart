import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../providers/iptv_provider.dart';
import '../utils/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;
  bool _isFullscreen = false;
  late AnimatedController _fadeController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.channel.url),
      );

      await _controller!.initialize();
      await _controller!.play();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Unable to load stream. The channel may be offline.';
        });
      }
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Video Area
          _buildVideoArea(),
          if (!_isFullscreen) ...[
            // Channel Info
            _buildChannelInfo(),
            // Controls bar
            _buildBottomControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: _isFullscreen
            ? MediaQuery.of(context).size.height
            : MediaQuery.of(context).size.width * 9 / 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            if (_controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            else if (!_hasError)
              _buildLoadingState(),

            // Error state
            if (_hasError) _buildErrorState(),

            // Controls overlay
            if (_showControls && !_hasError && !_isLoading)
              _buildControlsOverlay(),

            // Top bar with back & channel name
            if (_showControls || _isFullscreen)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading stream...',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_off_rounded, color: AppTheme.textMuted, size: 48),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Stream unavailable',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _initPlayer,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: _isFullscreen ? 40 : MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 20,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
            onPressed: () {
              if (_isFullscreen) {
                _toggleFullscreen();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 4),
          if (widget.channel.logo != null && widget.channel.logo!.isNotEmpty)
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: widget.channel.logo!,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          Expanded(
            child: Text(
              widget.channel.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.live,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 6),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.black38, Colors.transparent],
          radius: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: Icons.replay_10_rounded,
            onTap: () => _controller?.seekTo(
              (_controller!.value.position - const Duration(seconds: 10)),
            ),
          ),
          const SizedBox(width: 24),
          _buildControlButton(
            icon: _controller?.value.isPlaying == true
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 56,
            onTap: () {
              if (_controller?.value.isPlaying == true) {
                _controller?.pause();
              } else {
                _controller?.play();
              }
              setState(() {});
            },
          ),
          const SizedBox(width: 24),
          _buildControlButton(
            icon: Icons.forward_10_rounded,
            onTap: () => _controller?.seekTo(
              (_controller!.value.position + const Duration(seconds: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 40,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.7),
      ),
    );
  }

  Widget _buildChannelInfo() {
    final provider = context.read<IPTVProvider>();
    return Consumer<IPTVProvider>(
      builder: (context, prov, _) {
        final fav = prov.isFavorite(widget.channel);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          color: AppTheme.surface,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.channel.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (widget.channel.group != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.channel.group!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => prov.toggleFavorite(widget.channel),
                icon: Icon(
                  fav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: fav ? AppTheme.accentGold : AppTheme.textSecondary,
                  size: 26,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          _buildActionButton(
            Icons.open_in_full_rounded,
            'Fullscreen',
            _toggleFullscreen,
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            Icons.refresh_rounded,
            'Reload',
            _initPlayer,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _hasError ? AppTheme.error : AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _hasError ? 'Offline' : _isLoading ? 'Buffering...' : 'HD',
                  style: TextStyle(
                    color: _hasError ? AppTheme.error : AppTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
