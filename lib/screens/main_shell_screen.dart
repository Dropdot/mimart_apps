import 'dart:async';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'cart_screen.dart';
import 'category_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int index = 0;
  int cartCount = 0;
  int orderCount = 0;
  int notificationCount = 0;
  int chatUnreadCount = 0;
  Timer? _badgeTimer;

  static const maroon = Color(0xFF97002B);

  @override
  void initState() {
    super.initState();
    loadBadges();
    _badgeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) loadBadges();
    });
  }

  Map<String, dynamic> dataOrRoot(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return res;
  }

  Future<void> loadBadges() async {
    try {
      final res = await ApiClient.get('app_counts.php');
      final data = dataOrRoot(res);

      if (!mounted) return;

      setState(() {
        cartCount = int.tryParse('${data['cart_count'] ?? 0}') ?? 0;
        orderCount = int.tryParse('${data['order_count'] ?? 0}') ?? 0;
      });
      // load notification count
      try {
        final r2 = await ApiClient.get('notification_count.php');
        final d2 = dataOrRoot(r2);
        final n = d2['count'] ?? d2['label'] ?? 0;
        final nv = n is int ? n : int.tryParse('$n') ?? 0;
        if (!mounted) return;
        setState(() => notificationCount = nv);
      } catch (_) {}

      // load chat unread count
      try {
        final r3 = await ApiClient.get('chat_unread_count.php');
        final d3 = r3['data'] as Map<String, dynamic>? ?? r3;
        final c = d3['unread_count'] ?? d3['count'] ?? 0;
        final cv = c is int ? c : int.tryParse('$c') ?? 0;
        if (!mounted) return;
        setState(() => chatUnreadCount = cv);
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      setState(() {
        cartCount = 0;
        orderCount = 0;
      });
    }
  }

  Widget pageAt() {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const CategoryScreen();
      case 2:
        return CartScreen(onCartChanged: loadBadges);
      case 3:
        return const OrdersScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  Widget badgeIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -7,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pageAt(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) {
          setState(() => index = value);
          loadBadges();
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: maroon,
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.home_rounded),
                if (notificationCount > 0 || chatUnreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white, width: 1.5)),
                    ),
                  ),
              ],
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.category_rounded),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(
            icon: badgeIcon(Icons.shopping_cart_rounded, cartCount),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: badgeIcon(Icons.receipt_long_rounded, orderCount),
            label: 'Pesanan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }
}
