import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/channel_card.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

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
            _buildSearchBar(provider),
            if (provider.playlists.isNotEmpty) ...[
              _buildGroupFilter(provider),
            ],
            Expanded(child: _buildChannelList(provider)),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(IPTVProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: provider.setSearchQuery,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search channels...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
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

  Widget _buildGroupFilter(IPTVProvider provider) {
    final groups = provider.groups;
    if (groups.isEmpty) return const SizedBox();

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: groups.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildGroupChip(
              'All',
              provider.selectedGroup == null,
              () => provider.setSelectedGroup(null),
            );
          }
          final group = groups[index - 1];
          return _buildGroupChip(
            group,
            provider.selectedGroup == group,
            () => provider.setSelectedGroup(
              provider.selectedGroup == group ? null : group,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.background : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelList(IPTVProvider provider) {
    if (provider.isLoading) {
      return ListView.builder(
        itemCount: 10,
        itemBuilder: (_, __) => const ChannelCardShimmer(),
        padding: const EdgeInsets.only(top: 8),
      );
    }

    if (provider.playlists.isEmpty) {
      return _buildEmptyState(provider);
    }

    final channels = provider.filteredChannels;

    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            const Text('No channels found',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isSelected = provider.currentChannel?.id == channel.id;
        final isFav = provider.isFavorite(channel);

        return ChannelCard(
          channel: channel,
          isSelected: isSelected,
          isFavorite: isFav,
          onTap: () {
            provider.setCurrentChannel(channel);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(channel: channel),
              ),
            );
          },
          onFavoriteToggle: () => provider.toggleFavorite(channel),
        );
      },
    );
  }

  Widget _buildEmptyState(IPTVProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.live_tv_rounded,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Playlists Added',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add an M3U playlist to start watching your favorite channels',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: provider.loadDemoPlaylist,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Try Demo Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
