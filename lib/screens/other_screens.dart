import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import '../widgets/channel_card.dart';
import 'player_screen.dart';

// ==================== FAVORITES ====================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<IPTVProvider>(
      builder: (context, provider, _) {
        if (provider.favorites.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border_rounded, color: Color(0xFF3D4F6B), size: 64),
              SizedBox(height: 16),
              Text('لا توجد مفضلة', style: TextStyle(color: Color(0xFFEEF2FF), fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('اضغط على ★ لإضافة قناة', style: TextStyle(color: Color(0xFF7C8DB0), fontSize: 13)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 100),
          itemCount: provider.favorites.length,
          itemBuilder: (context, i) {
            final ch = provider.favorites[i];
            return ChannelCard(
              channel: ch,
              isSelected: provider.currentChannel?.id == ch.id,
              isFavorite: true,
              onTap: () {
                provider.setCurrentChannel(ch);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch)));
              },
              onFavoriteToggle: () => provider.toggleFavorite(ch),
            );
          },
        );
      },
    );
  }
}

// ==================== RECENT ====================
class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<IPTVProvider>(
      builder: (context, provider, _) {
        if (provider.recentChannels.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, color: Color(0xFF3D4F6B), size: 64),
              SizedBox(height: 16),
              Text('لا يوجد سجل', style: TextStyle(color: Color(0xFFEEF2FF), fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('القنوات التي تشاهدها ستظهر هنا', style: TextStyle(color: Color(0xFF7C8DB0), fontSize: 13)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 100),
          itemCount: provider.recentChannels.length,
          itemBuilder: (context, i) {
            final ch = provider.recentChannels[i];
            return ChannelCard(
              channel: ch,
              isSelected: provider.currentChannel?.id == ch.id,
              isFavorite: provider.isFavorite(ch),
              onTap: () {
                provider.setCurrentChannel(ch);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch)));
              },
              onFavoriteToggle: () => provider.toggleFavorite(ch),
            );
          },
        );
      },
    );
  }
}

// ==================== PLAYLISTS ====================
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IPTVProvider>(
      builder: (context, provider, _) {
        // عرض خطأ إن وجد
        if (provider.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.error!),
                backgroundColor: const Color(0xFFFF3D57),
                action: SnackBarAction(
                  label: 'إغلاق',
                  textColor: Colors.white,
                  onPressed: provider.clearError,
                ),
              ),
            );
            provider.clearError();
          });
        }

        return Column(
          children: [
            Expanded(
              child: provider.playlists.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.playlists.length,
                      itemBuilder: (ctx, i) => _buildItem(ctx, provider, i),
                    ),
            ),
            _buildButtons(context),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.playlist_play_rounded, color: Color(0xFF3D4F6B), size: 64),
        SizedBox(height: 16),
        Text('لا توجد قوائم', style: TextStyle(color: Color(0xFFEEF2FF), fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('أضف قائمة M3U عبر رابط أو ملف', style: TextStyle(color: Color(0xFF7C8DB0), fontSize: 13)),
      ],
    ));
  }

  Widget _buildItem(BuildContext context, IPTVProvider provider, int index) {
    final playlist = provider.playlists[index];
    final isSelected = provider.selectedPlaylistIndex == index;
    final isFile = playlist.url.startsWith('/');

    return GestureDetector(
      onTap: () => provider.selectPlaylist(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4FF).withOpacity(0.1) : const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D4FF).withOpacity(0.4) : const Color(0xFF252D3F),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00D4FF).withOpacity(0.2) : const Color(0xFF161E2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isFile ? Icons.folder_rounded : Icons.playlist_play_rounded,
                color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF7C8DB0),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFFEEF2FF),
                      fontSize: 15, fontWeight: FontWeight.w700,
                    )),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(
                      isFile ? Icons.storage_rounded : Icons.link_rounded,
                      color: const Color(0xFF3D4F6B), size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${playlist.channels.length} قناة • ${isFile ? "ملف محلي" : "رابط"}',
                      style: const TextStyle(color: Color(0xFF7C8DB0), fontSize: 12),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('نشط',
                          style: TextStyle(color: Color(0xFF080C14), fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF7C8DB0)),
              color: const Color(0xFF1A2235),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'refresh') provider.refreshPlaylist(index);
                if (value == 'delete') _confirmDelete(context, provider, index, playlist.name);
              },
              itemBuilder: (_) => [
                if (!isFile) const PopupMenuItem(value: 'refresh',
                  child: Row(children: [
                    Icon(Icons.refresh_rounded, color: Color(0xFF7C8DB0), size: 18),
                    SizedBox(width: 10),
                    Text('تحديث', style: TextStyle(color: Color(0xFFEEF2FF))),
                  ])),
                const PopupMenuItem(value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3D57), size: 18),
                    SizedBox(width: 10),
                    Text('حذف', style: TextStyle(color: Color(0xFFFF3D57))),
                  ])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, IPTVProvider provider, int index, String name) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A2235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف القائمة', style: TextStyle(color: Color(0xFFEEF2FF))),
      content: Text('هل تريد حذف "$name"؟', style: const TextStyle(color: Color(0xFF7C8DB0))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Color(0xFF7C8DB0)))),
        TextButton(
          onPressed: () { provider.removePlaylist(index); Navigator.pop(context); },
          child: const Text('حذف', style: TextStyle(color: Color(0xFFFF3D57))),
        ),
      ],
    ));
  }

  Widget _buildButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1623),
        border: Border(top: BorderSide(color: Color(0xFF252D3F))),
      ),
      child: Column(
        children: [
          // زر إضافة عبر رابط
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddUrlDialog(context),
              icon: const Icon(Icons.link_rounded),
              label: const Text('إضافة عبر رابط'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: const Color(0xFF080C14),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // زر إضافة من ملف
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.read<IPTVProvider>().addPlaylistFromFile(),
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('إضافة من الذاكرة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00D4FF),
                side: const BorderSide(color: Color(0xFF00D4FF)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUrlDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة قائمة', style: TextStyle(color: Color(0xFFEEF2FF), fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Color(0xFFEEF2FF)),
                decoration: const InputDecoration(
                  hintText: 'اسم القائمة',
                  prefixIcon: Icon(Icons.label_outline_rounded, color: Color(0xFF3D4F6B)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                style: const TextStyle(color: Color(0xFFEEF2FF)),
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'رابط M3U / M3U8',
                  prefixIcon: Icon(Icons.link_rounded, color: Color(0xFF3D4F6B)),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: Color(0xFF7C8DB0))),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final url = urlCtrl.text.trim();
                    if (name.isNotEmpty && url.isNotEmpty) {
                      context.read<IPTVProvider>().addPlaylist(name, url);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF),
                    foregroundColor: const Color(0xFF080C14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('إضافة'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
