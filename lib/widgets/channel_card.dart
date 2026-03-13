import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const ChannelCard({
    super.key,
    required this.channel,
    this.isSelected = false,
    this.isFavorite = false,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00D4FF).withOpacity(0.12)
              : const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00D4FF).withOpacity(0.5)
                : const Color(0xFF252D3F),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildLogo(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF00D4FF)
                            : const Color(0xFFEEF2FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (channel.group != null && channel.group!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF2D55),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'LIVE • ${channel.group}',
                            style: const TextStyle(
                              color: Color(0xFF7C8DB0),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onFavoriteToggle != null)
                GestureDetector(
                  onTap: onFavoriteToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF3D4F6B),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF161E2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF252D3F)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: channel.logo != null && channel.logo!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: channel.logo!,
                fit: BoxFit.contain,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    final letter = channel.name.isNotEmpty ? channel.name[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFF161E2E),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Color(0xFF00D4FF),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class ChannelCardShimmer extends StatelessWidget {
  const ChannelCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
