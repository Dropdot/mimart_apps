import 'package:flutter/material.dart';

class PremiumFeatureStrip extends StatelessWidget {
  const PremiumFeatureStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.workspace_premium_outlined, 'Premium'),
      (Icons.edit_note_outlined, 'Custom'),
      (Icons.verified_user_outlined, 'Aman'),
      (Icons.local_shipping_outlined, 'Cepat'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBD7DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Column(
              children: [
                Icon(item.$1, color: const Color(0xFF97002B), size: 21),
                const SizedBox(height: 4),
                Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10.4),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
