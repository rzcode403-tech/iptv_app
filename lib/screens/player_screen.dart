import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../providers/iptv_provider.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.channel.url));
      await _controller!.initialize();
      await _controller!.play();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
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
      backgroundColor: const Color(0xFF080C14),
      body: Column(
        children: [
          _buildVideoArea(),
          if (!_isFullscreen) ...[
            _buildChannelInfo(),
            _buildControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    final h = _isFullscreen
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.width * 9 / 16;

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            else if (!_hasError)
              const CircularProgressIndicator(color: Color(0xFF00D4FF)),

            if (_hasError)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Color(0xFF3D4F6B), size: 48),
                  const SizedBox(height: 12),
                  const Text('Stream unavailable',
                      style: TextStyle(color: Color(0xFF7C8DB0))),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _initPlayer,
                    child: const Text('Retry', style: TextStyle(color: Color(0xFF00D4FF))),
                  ),
                ],
              ),

            if (_showControls && !_hasError && !_isLoading)
              _buildControlsOverlay(),

            if (_showControls)
              Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          ],
        ),
      ),
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
        left: 8, right: 8, bottom: 20,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
            onPressed: () {
              if (_isFullscreen) _toggleFullscreen();
              else Navigator.pop(context);
            },
          ),
          if (widget.channel.logo != null && widget.channel.logo!.isNotEmpty)
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white12,
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
            child: Text(widget.channel.name,
                style: const TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF2D55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 6),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white,
                    fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ctrlBtn(Icons.replay_10_rounded, () =>
            _controller?.seekTo(_controller!.value.position - const Duration(seconds: 10))),
        const SizedBox(width: 24),
        _ctrlBtn(
          _controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
          () { setState(() {
            _controller?.value.isPlaying == true ? _controller?.pause() : _controller?.play();
          }); },
          size: 56,
        ),
        const SizedBox(width: 24),
        _ctrlBtn(Icons.forward_10_rounded, () =>
            _controller?.seekTo(_controller!.value.position + const Duration(seconds: 10))),
      ],
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap, {double size = 40}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 16, height: size + 16,
        decoration: BoxDecoration(
          color: Colors.black38, shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.7),
      ),
    );
  }

  Widget _buildChannelInfo() {
    return Consumer<IPTVProvider>(
      builder: (context, prov, _) {
        final fav = prov.isFavorite(widget.channel);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          color: const Color(0xFF0F1623),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.channel.name,
                        style: const TextStyle(color: Color(0xFFEEF2FF),
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    if (widget.channel.group != null) ...[
                      const SizedBox(height: 4),
                      Text(widget.channel.group!,
                          style: const TextStyle(color: Color(0xFF7C8DB0), fontSize: 13)),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => prov.toggleFavorite(widget.channel),
                icon: Icon(
                  fav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: fav ? const Color(0xFFFFB800) : const Color(0xFF7C8DB0),
                  size: 26,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF0F1623),
      child: Row(
        children: [
          _actionBtn(Icons.open_in_full_rounded, 'Fullscreen', _toggleFullscreen),
          const SizedBox(width: 12),
          _actionBtn(Icons.refresh_rounded, 'Reload', _initPlayer),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF252D3F)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _hasError ? const Color(0xFFFF3D57) : const Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _hasError ? 'Offline' : _isLoading ? 'Buffering...' : 'HD',
                  style: TextStyle(
                    color: _hasError ? const Color(0xFFFF3D57) : const Color(0xFF00E676),
                    fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161E2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF252D3F)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7C8DB0), size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Color(0xFF7C8DB0),
                fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
