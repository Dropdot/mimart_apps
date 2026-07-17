import 'package:flutter/material.dart';

class CategoryChipItem extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChipItem({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  String get title {
    return (category['display_name'] ??
            category['name'] ??
            category['category_name'] ??
            category['title'] ??
            category['slug'] ??
            'Kategori')
        .toString();
  }

  IconData get icon {
    final text = title.toLowerCase();

    if (text.contains('desain')) return Icons.palette_outlined;
    if (text.contains('souvenir') || text.contains('custom')) return Icons.card_giftcard_rounded;
    if (text.contains('merch')) return Icons.local_mall_outlined;

    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF97002B) : Colors.white;
    final fg = selected ? Colors.white : const Color(0xFF374151);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF97002B) : const Color(0xFFEBD7DD),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: fg,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
