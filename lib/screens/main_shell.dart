import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import 'home_screen.dart';
import 'other_screens.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    FavoritesScreen(),
    RecentScreen(),
    PlaylistsScreen(),
  ];

  final _labels = ['Live TV', 'Favorites', 'Recent', 'Playlists'];
  final _icons = [
    Icons.live_tv_rounded,
    Icons.star_rounded,
    Icons.history_rounded,
    Icons.playlist_play_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<IPTVProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF080C14),
          appBar: _buildAppBar(provider),
          body: Stack(
            children: [
              IndexedStack(index: _currentIndex, children: _screens),
              if (provider.isLoading)
                Container(
                  color: const Color(0xFF080C14).withOpacity(0.8),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2.5),
                        SizedBox(height: 16),
                        Text('Loading playlist...',
                            style: TextStyle(color: Color(0xFF7C8DB0), fontSize: 14)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(IPTVProvider provider) {
    return AppBar(
      backgroundColor: const Color(0xFF080C14),
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tv_rounded, color: Color(0xFF080C14), size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('IPTV Pro',
                  style: TextStyle(color: Color(0xFFEEF2FF),
                      fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              if (provider.currentPlaylist != null)
                Text(provider.currentPlaylist!.name,
                    style: const TextStyle(color: Color(0xFF00D4FF),
                        fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
      actions: [
        if (provider.allChannels.isNotEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF161E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF252D3F)),
              ),
              child: Text('${provider.allChannels.length} ch',
                  style: const TextStyle(color: Color(0xFF7C8DB0),
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFF252D3F), height: 1),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1623),
        border: Border(top: BorderSide(color: Color(0xFF252D3F))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (i) {
              final selected = _currentIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF00D4FF).withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icons[i],
                          color: selected ? const Color(0xFF00D4FF) : const Color(0xFF7C8DB0),
                          size: 22),
                      const SizedBox(height: 3),
                      Text(_labels[i],
                          style: TextStyle(
                            color: selected ? const Color(0xFF00D4FF) : const Color(0xFF7C8DB0),
                            fontSize: 10, fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
