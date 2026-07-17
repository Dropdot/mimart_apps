import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/product_display_helper.dart';

class ProductPriceBlock extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool compact;

  const ProductPriceBlock({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final price = ProductDisplayHelper.price(product);
    final strike = ProductDisplayHelper.strikePrice(product);
    final hasStrike = ProductDisplayHelper.hasStrikePrice(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasStrike)
          Text(
            Formatters.rupiah(strike),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.black38,
              fontSize: compact ? 10.2 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        Text(
          Formatters.rupiah(price),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF97002B),
            fontWeight: FontWeight.w900,
            fontSize: compact ? 12.6 : 21,
          ),
        ),
      ],
    );
  }
}
