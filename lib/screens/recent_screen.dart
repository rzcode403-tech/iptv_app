import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/channel_card.dart';
import 'player_screen.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IPTVProvider>(
      builder: (context, provider, _) {
        if (provider.recentChannels.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, color: AppTheme.textMuted, size: 64),
                SizedBox(height: 16),
                Text(
                  'No History Yet',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Channels you watch will appear here',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 100),
          itemCount: provider.recentChannels.length,
          itemBuilder: (context, index) {
            final channel = provider.recentChannels[index];
            return ChannelCard(
              channel: channel,
              isSelected: provider.currentChannel?.id == channel.id,
              isFavorite: provider.isFavorite(channel),
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
      },
    );
  }
}
