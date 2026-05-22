import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppMediaImage extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final Color accent;
  final double width;
  final double height;
  final double radius;

  const AppMediaImage({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.accent,
    required this.width,
    required this.height,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _Fallback(
                  icon: fallbackIcon,
                  accent: accent,
                ),
                errorWidget: (_, __, ___) => _Fallback(
                  icon: fallbackIcon,
                  accent: accent,
                ),
              )
            : _Fallback(icon: fallbackIcon, accent: accent),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _Fallback({
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
      ),
      child: Icon(icon, color: accent, size: 24),
    );
  }
}
