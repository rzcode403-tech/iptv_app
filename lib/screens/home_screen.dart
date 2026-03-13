import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import '../widgets/channel_card.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IPTVProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            _buildSearch(provider),
            if (provider.playlists.isNotEmpty) _buildGroups(provider),
            Expanded(child: _buildList(provider)),
          ],
        );
      },
    );
  }

  Widget _buildSearch(IPTVProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: provider.setSearchQuery,
        style: const TextStyle(color: Color(0xFFEEF2FF)),
        decoration: InputDecoration(
          hintText: 'Search channels...',
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3D4F6B)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF3D4F6B)),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildGroups(IPTVProvider provider) {
    final groups = provider.groups;
    if (groups.isEmpty) return const SizedBox();
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: groups.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _chip('All', provider.selectedGroup == null,
              () => provider.setSelectedGroup(null));
          final g = groups[i - 1];
          return _chip(g, provider.selectedGroup == g,
              () => provider.setSelectedGroup(provider.selectedGroup == g ? null : g));
        },
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00D4FF) : const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF00D4FF) : const Color(0xFF252D3F),
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: selected ? const Color(0xFF080C14) : const Color(0xFF7C8DB0),
                fontSize: 12, fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }

  Widget _buildList(IPTVProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)));
    }
    if (provider.playlists.isEmpty) return _buildEmpty(provider);

    final channels = provider.filteredChannels;
    if (channels.isEmpty) {
      return const Center(
        child: Text('No channels found',
            style: TextStyle(color: Color(0xFF7C8DB0), fontSize: 15)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: channels.length,
      itemBuilder: (context, i) {
        final ch = channels[i];
        return ChannelCard(
          channel: ch,
          isSelected: provider.currentChannel?.id == ch.id,
          isFavorite: provider.isFavorite(ch),
          onTap: () {
            provider.setCurrentChannel(ch);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch)));
          },
          onFavoriteToggle: () => provider.toggleFavorite(ch),
        );
      },
    );
  }

  Widget _buildEmpty(IPTVProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2235),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF252D3F)),
              ),
              child: const Icon(Icons.live_tv_rounded, color: Color(0xFF00D4FF), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('No Playlists Added',
                style: TextStyle(color: Color(0xFFEEF2FF),
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Add an M3U playlist to start watching',
                style: TextStyle(color: Color(0xFF7C8DB0), fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
