import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/image_url_helper.dart';
import '../core/product_display_helper.dart';
import '../core/video_display_helper.dart';

class HomeMediaPromoGrid extends StatelessWidget {
  final List<dynamic> videos;
  final List<dynamic> flashSale;
  final VoidCallback onTapVideoAll;
  final VoidCallback onTapFlashAll;
  final void Function(Map<String, dynamic> video) onTapVideoItem;
  final void Function(Map<String, dynamic> product) onTapFlashItem;

  const HomeMediaPromoGrid({
    super.key,
    required this.videos,
    required this.flashSale,
    required this.onTapVideoAll,
    required this.onTapFlashAll,
    required this.onTapVideoItem,
    required this.onTapFlashItem,
  });

  @override
  Widget build(BuildContext context) {
    final flashPreview = flashSale.take(3).toList();
    final videoPreview = videos.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PreviewPanel(
              title: 'FLASH SALE',
              subtitle: 'Promo varian terbatas',
              icon: Icons.flash_on_rounded,
              badge: 'Promo Aktif',
              actionText: 'Lihat semua →',
              accent: const Color(0xFFE11D48),
              onTapAction: onTapFlashAll,
              child: flashPreview.isEmpty
                  ? const _EmptyPreview(
                      icon: Icons.flash_on_rounded,
                      text: 'Flash Sale belum tersedia',
                    )
                  : _FlashPreviewList(
                      products: flashPreview,
                      onTap: onTapFlashItem,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PreviewPanel(
              title: 'MI MART TV',
              subtitle: 'Video terbaru',
              icon: Icons.movie_filter_rounded,
              badge: '',
              actionText: 'Lihat semua →',
              accent: const Color(0xFF303B55),
              onTapAction: onTapVideoAll,
              child: videoPreview.isEmpty
                  ? const _EmptyPreview(
                      icon: Icons.play_circle_outline_rounded,
                      text: 'Video belum tersedia',
                    )
                  : _VideoPreviewList(
                      videos: videoPreview,
                      onTap: onTapVideoItem,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String actionText;
  final IconData icon;
  final Color accent;
  final VoidCallback onTapAction;
  final Widget child;

  const _PreviewPanel({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.actionText,
    required this.icon,
    required this.accent,
    required this.onTapAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 194,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBD7DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.2, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.7,
                    height: 1.18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (badge.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Color(0xFFE11D48),
                      fontSize: 9.7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onTapAction,
              child: Text(
                actionText,
                style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _FlashPreviewList extends StatelessWidget {
  final List<dynamic> products;
  final void Function(Map<String, dynamic> product) onTap;

  const _FlashPreviewList({
    required this.products,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: products.map((raw) {
        final product = Map<String, dynamic>.from(raw as Map);
        final image = ImageUrlHelper.fromProduct(product);
        final price = ProductDisplayHelper.price(product);
        final discount = ProductDisplayHelper.discountPercent(product);

        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(product),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEFE3E7)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFFEEF2),
                        child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF97002B), size: 22),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(.03), Colors.black.withOpacity(.52)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  if (discount > 0)
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(color: Colors.white, fontSize: 8.2, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 5,
                    right: 5,
                    bottom: 5,
                    child: Text(
                      Formatters.rupiah(price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 9.2, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VideoPreviewList extends StatelessWidget {
  final List<dynamic> videos;
  final void Function(Map<String, dynamic> video) onTap;

  const _VideoPreviewList({
    required this.videos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: videos.map((raw) {
        final video = Map<String, dynamic>.from(raw as Map);
        final title = VideoDisplayHelper.title(video);
        final thumbnail = VideoDisplayHelper.thumbnail(video);

        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(video),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2433),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (thumbnail.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(.08), Colors.black.withOpacity(.62)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
                  ),
                  Positioned(
                    left: 5,
                    right: 5,
                    bottom: 5,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.8,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyPreview({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF97002B), size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10.4,
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
