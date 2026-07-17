import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/image_url_helper.dart';
import 'product_network_image.dart';

class PremiumProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onFavoriteTap;

  const PremiumProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onCartTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = ImageUrlHelper.fromProduct(product);
    final price = product['base_price'] ?? product['price'] ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF1DCE2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.08,
                  child: ProductNetworkImage(
                    url: image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      onPressed: onFavoriteTap,
                      icon: const Icon(Icons.favorite_border),
                      color: const Color(0xFF800020),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product['name'] ?? '-').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.rupiah(price),
                      style: const TextStyle(
                        color: Color(0xFF97002B),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEF2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: onCartTap,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                            color: const Color(0xFF97002B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: FilledButton.icon(
                              onPressed: onCartTap,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF97002B),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'Keranjang',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
