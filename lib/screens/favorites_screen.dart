import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/channel_card.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IPTVProvider>(
      builder: (context, provider, _) {
        if (provider.favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_border_rounded,
                    color: AppTheme.textMuted, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'No Favorites Yet',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Star your favorite channels to find them quickly',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 100),
          itemCount: provider.favorites.length,
          itemBuilder: (context, index) {
            final channel = provider.favorites[index];
            return ChannelCard(
              channel: channel,
              isSelected: provider.currentChannel?.id == channel.id,
              isFavorite: true,
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
