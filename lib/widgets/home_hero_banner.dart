import 'package:flutter/material.dart';

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB00035), Color(0xFF72001F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFF97002B).withOpacity(.20), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -15, bottom: -18, child: Icon(Icons.shopping_bag_outlined, size: 116, color: Colors.white.withOpacity(.13))),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 15, 92, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.17), borderRadius: BorderRadius.circular(999)),
                  child: const Text('Premium Custom', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Custom & Souvenir\nBerkualitas Premium',
                  style: TextStyle(color: Colors.white, fontSize: 19.5, height: 1.03, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                const Text(
                  'Desain unik untuk momen spesial Anda',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
