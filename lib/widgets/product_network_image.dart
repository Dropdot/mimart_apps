import 'package:flutter/material.dart';

class ProductNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFFBEAEC),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF9F1239), size: 28),
        ),
      );
    }

    final image = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      headers: const {
        'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFF3E7EA),
          child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
        );
      },
      errorBuilder: (context, error, stackTrace) => fallback(),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
