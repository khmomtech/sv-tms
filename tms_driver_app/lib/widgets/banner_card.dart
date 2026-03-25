import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'smart_banner_image.dart';

class BannerCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const BannerCard({
    super.key,
    this.imageUrl,
    this.title,
    this.subtitle,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // 10% black
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl!.trim().isNotEmpty)
                SmartBannerImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported,
                        size: 50, color: Colors.grey),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors ??
                          [Colors.blue.shade700, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

              if (title != null || subtitle != null)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x99000000), // 60% black
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),

              if (title != null || subtitle != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Builder(builder: (context) {
                          final style = Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ) ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                  ),
                                ],
                              );
                          return Text(
                            title!,
                            style: style,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Builder(builder: (context) {
                          final style = Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ) ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                  ),
                                ],
                              );
                          return Text(
                            subtitle!,
                            style: style,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
