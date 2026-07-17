import 'package:flutter/material.dart';
import '../screens/product_detail_screen.dart';
import 'compact_product_card.dart';
import 'section_title.dart';

class FlashSaleHorizontal extends StatelessWidget {
  final List<dynamic> products;
  final Future<void> Function(Map<String, dynamic> product) onAddCart;
  final VoidCallback? onSeeAll;

  const FlashSaleHorizontal({super.key, required this.products, required this.onAddCart, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SectionTitle(title: 'Flash Sale', actionText: 'Lihat semua', onAction: onSeeAll),
        SizedBox(
          height: 228,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final product = Map<String, dynamic>.from(products[i] as Map);
              return SizedBox(
                width: 150,
                child: CompactProductCard(
                  product: product,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                  onCartTap: () => onAddCart(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
