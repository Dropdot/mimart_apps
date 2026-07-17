import 'package:flutter/material.dart';

import '../core/product_display_helper.dart';

class ProductRatingRow extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool compact;

  const ProductRatingRow({
    super.key,
    required this.product,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final rating = ProductDisplayHelper.rating(product);
    final count = ProductDisplayHelper.ratingCount(product);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFB703), size: 14),
        const SizedBox(width: 2),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : 'Baru',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF5F4B52),
            fontSize: compact ? 10.7 : 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 2),
          Text(
            '($count)',
            style: TextStyle(
              color: Colors.black38,
              fontSize: compact ? 10.2 : 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
