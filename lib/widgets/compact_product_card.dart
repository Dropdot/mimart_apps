import 'package:flutter/material.dart';

import '../core/image_url_helper.dart';
import 'product_network_image.dart';
import 'product_price_block.dart';
import 'product_rating_row.dart';
import 'sale_badge.dart';

class CompactProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onFavoriteTap;

  const CompactProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onCartTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = ImageUrlHelper.fromProduct(product);
    final name = (product['name'] ?? '-').toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0DCE2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.16,
                    child: ProductNetworkImage(
                      url: image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(left: 6, top: 6, child: SaleBadge(product: product)),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.94),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFF97002B)),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11.6,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      ProductRatingRow(product: product),
                      const SizedBox(height: 3),
                      ProductPriceBlock(product: product, compact: true),
                      const Spacer(),
                      SizedBox(
                        height: 29,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onCartTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF97002B),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add, size: 15),
                          label: const Text(
                            'Keranjang',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
