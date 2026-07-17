import 'package:flutter/material.dart';

import '../core/product_display_helper.dart';

class SaleBadge extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool small;

  const SaleBadge({
    super.key,
    required this.product,
    this.small = true,
  });

  @override
  Widget build(BuildContext context) {
    final discount = ProductDisplayHelper.discountPercent(product);
    final flash = ProductDisplayHelper.isFlashSale(product);

    if (discount <= 0 && !flash) {
      return const SizedBox.shrink();
    }

    final label = flash ? (discount > 0 ? 'FLASH -$discount%' : 'FLASH') : '-$discount%';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 10,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withOpacity(.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 9.5 : 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
