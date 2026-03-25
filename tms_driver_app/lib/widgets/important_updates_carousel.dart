import 'dart:async';

import 'package:flutter/material.dart';

class ImportantUpdate {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback? onTap;

  ImportantUpdate({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.onTap,
  });
}

class ImportantUpdatesCarousel extends StatefulWidget {
  final List<ImportantUpdate> updates;

  /// Auto-slide interval. Set to null to disable.
  final Duration autoPlayInterval;

  const ImportantUpdatesCarousel({
    Key? key,
    required this.updates,
    this.autoPlayInterval = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<ImportantUpdatesCarousel> createState() =>
      _ImportantUpdatesCarouselState();
}

class _ImportantUpdatesCarouselState extends State<ImportantUpdatesCarousel> {
  int _current = 0;
  late final PageController _pageController;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.updates.length <= 1) return;
    _autoPlayTimer =
        Timer.periodic(widget.autoPlayInterval, (_) => _advancePage());
  }

  void _advancePage() {
    if (!mounted || widget.updates.isEmpty) return;
    final next = (_current + 1) % widget.updates.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _pauseAndResume() {
    _autoPlayTimer?.cancel();
    // Resume after a short pause while user interacts
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.updates.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.updates.length,
            onPageChanged: (index) {
              setState(() => _current = index);
            },
            itemBuilder: (context, index) {
              final update = widget.updates[index];
              return GestureDetector(
                onTap: () {
                  _pauseAndResume();
                  update.onTap?.call();
                },
                onPanDown: (_) => _pauseAndResume(),
                child: _BannerCard(update: update),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _DotIndicator(
          count: widget.updates.length,
          currentIndex: _current,
        ),
      ],
    );
  }
}

/// Individual banner card with network image, gradient, shimmer fallback.
class _BannerCard extends StatelessWidget {
  final ImportantUpdate update;
  const _BannerCard({required this.update});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image from API
            Image.network(
              update.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return _ShimmerPlaceholder();
              },
              errorBuilder: (_, __, ___) => _ImageFallback(),
            ),
            // Gradient overlay for readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.72),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            // Text content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      update.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (update.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        update.subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          shadows: [
                            Shadow(blurRadius: 3, color: Colors.black54),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated dot indicator — active dot is a pill, others are circles.
class _DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _DotIndicator({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final primary = Theme.of(context).primaryColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isActive ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? primary : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

/// Pulsing shimmer while image loads.
class _ShimmerPlaceholder extends StatefulWidget {
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(color: Colors.grey.shade200),
    );
  }
}

/// Shown when image URL fails to load.
class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.white38, size: 48),
      ),
    );
  }
}
