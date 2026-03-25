import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tms_driver_app/widgets/banner_card.dart';

/// Dashboard Image Carousel
/// Displays promotional banners, announcements, and important notices
class DashboardImageCarousel extends StatefulWidget {
  final List<CarouselItem> items;
  final double height;
  final Duration autoPlayInterval;
  final bool autoPlay;
  final bool showArrows;
  // Notifies parent when page changes.
  final ValueChanged<int>? onPageChanged;

  const DashboardImageCarousel({
    super.key,
    required this.items,
    this.height = 180,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.autoPlay = true,
    this.showArrows = true,
    this.onPageChanged,
  });

  @override
  State<DashboardImageCarousel> createState() =>
      _DashboardImageCarouselState();
}

class _DashboardImageCarouselState extends State<DashboardImageCarousel> {
  static const double _horizontalMargin = 16;
  static const double _verticalMargin = 8;
  static const double _arrowSideOffset = 8;
  static const double _dotHeight = 8.0;
  static const double _dotWidthActive = 24.0;
  static const double _dotWidthInactive = 8.0;

  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  void _goToPrevious() {
    if (widget.items.isEmpty) return;
    final target = (_currentIndex - 1) < 0
        ? widget.items.length - 1
        : _currentIndex - 1;
    _carouselController.animateToPage(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _goToNext() {
    if (widget.items.isEmpty) return;
    final target = (_currentIndex + 1) % widget.items.length;
    _carouselController.animateToPage(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: _horizontalMargin,
        vertical: _verticalMargin,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CarouselSlider(
            options: CarouselOptions(
              height: widget.height,
              autoPlay: widget.autoPlay,
              autoPlayInterval: widget.autoPlayInterval,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              viewportFraction: 0.92,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
                widget.onPageChanged?.call(index);
              },
                ),
                carouselController: _carouselController,
                items: widget.items.map((item) {
                  return Builder(
                    builder: (BuildContext context) {
                      return _buildCarouselItem(item);
                    },
                  );
                }).toList(),
              ),
              if (widget.showArrows) ...[
                Positioned(
                  left: _arrowSideOffset,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      icon: Icons.chevron_left,
                      onTap: _goToPrevious,
                      tooltip: 'carousel.previous'.tr(),
                      semanticLabel: 'carousel.previous'.tr(),
                    ),
                  ),
                ),
                Positioned(
                  right: _arrowSideOffset,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      icon: Icons.chevron_right,
                      onTap: _goToNext,
                      tooltip: 'carousel.next'.tr(),
                      semanticLabel: 'carousel.next'.tr(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _DotsIndicator(
            count: widget.items.length,
            currentIndex: _currentIndex,
            activeColor: Colors.red,
            inactiveColor: Colors.grey.shade300,
            dotHeight: _dotHeight,
            activeWidth: _dotWidthActive,
            inactiveWidth: _dotWidthInactive,
            onDotTap: (i) => _carouselController.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(CarouselItem item) {
    return BannerCard(
      imageUrl: (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty)
          ? item.imageUrl
          : null,
      title: item.title,
      subtitle: item.subtitle,
      gradientColors: item.gradientColors,
      onTap: item.onTap,
    );
  }
}

/// Model for carousel items
class CarouselItem {
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const CarouselItem({
    this.imageUrl,
    this.title,
    this.subtitle,
    this.gradientColors,
    this.onTap,
  });
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final String? semanticLabel;
  const _ArrowButton({required this.icon, required this.onTap, this.tooltip, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.black.withOpacity(0.25),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
    final withSemantics = Semantics(
      button: true,
      label: semanticLabel,
      child: button,
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: withSemantics);
    }
    return withSemantics;
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double dotHeight;
  final double activeWidth;
  final double inactiveWidth;
  final ValueChanged<int>? onDotTap;

  const _DotsIndicator({
    required this.count,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.dotHeight,
    required this.activeWidth,
    required this.inactiveWidth,
    this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool isActive = index == currentIndex;
        final double width = isActive ? activeWidth : inactiveWidth;
        final color = isActive ? activeColor : inactiveColor;
        final dot = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: width,
          height: dotHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(dotHeight / 2),
            color: color,
          ),
        );
        return onDotTap == null
            ? dot
            : GestureDetector(
                onTap: () => onDotTap!(index),
                behavior: HitTestBehavior.opaque,
                child: dot,
              );
      }),
    );
  }
}
