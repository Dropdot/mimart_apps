import 'dart:async';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_gate.dart';
import '../widgets/category_chip.dart';
import '../widgets/compact_product_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/home_media_promo_grid.dart';
import '../widgets/premium_feature_strip.dart';
import '../widgets/section_title.dart';
import '../widgets/video_player_sheet.dart';
import 'chat_screen.dart';
import 'flash_sale_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'video_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;
  String error = '';
  List<dynamic> categories = [];
  List<dynamic> products = [];
  List<dynamic> flashSale = [];
  List<dynamic> videos = [];
  int unreadChatCount = 0;
  int unreadNotificationCount = 0;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    load();
    // badge poll (chat + notification)
    _badgeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        loadChatBadge();
        loadNotificationBadge();
      }
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = '';
    });

    final res = await ApiClient.get('home.php');
    final data = res['data'] as Map<String, dynamic>? ?? {};

    if (res['status'] != 'success') {
      setState(() {
        error = res['message']?.toString() ?? 'Gagal memuat home';
        loading = false;
      });
      return;
    }

    setState(() {
      categories = data['categories'] as List<dynamic>? ?? [];
      products = data['products'] as List<dynamic>? ?? [];
      flashSale = data['flash_sale'] as List<dynamic>? ?? [];
      videos = data['videos'] as List<dynamic>? ?? [];
      loading = false;
    });

    // update badge after loading home
    loadChatBadge();
  }

  Future<void> loadChatBadge() async {
    try {
      final res = await ApiClient.get('chat_unread_count.php');
      final data = res['data'] as Map<String, dynamic>? ?? res;
      final cnt = data['unread_count'] ?? data['count'] ?? 0;
      final n = cnt is int ? cnt : int.tryParse('$cnt') ?? 0;
      if (!mounted) return;
      setState(() => unreadChatCount = n);
    } catch (_) {}
  }

  Future<void> loadNotificationBadge() async {
    try {
      final res = await ApiClient.get('notification_count.php');
      final data = res['data'] as Map<String, dynamic>? ?? res;
      final cnt = data['count'] ?? data['label'] ?? 0;
      final n = cnt is int ? cnt : int.tryParse('$cnt') ?? 0;
      if (!mounted) return;
      setState(() => unreadNotificationCount = n);
    } catch (_) {}
  }

  Future<void> addCart(Map<String, dynamic> product) async {
    final ok = await AuthGate.ensureLogin(context);
    if (!ok) return;

    final res = await ApiClient.post(
      'cart_add.php',
      body: {'product_id': product['id'], 'quantity': 1},
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message']?.toString() ?? 'Selesai')),
    );
  }

  Future<void> openPrivate(Widget page) async {
    final ok = await AuthGate.ensureLogin(context);
    if (!ok || !mounted) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void openVideo(Map<String, dynamic> video) {
    VideoPlayerSheet.open(context, video);
  }

  void openFlashProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('MI MART'),
        actions: [
          IconButton(
            tooltip: 'Cari',
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            visualDensity: VisualDensity.compact,
            onPressed: () => openPrivate(const NotificationsScreen()),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Chat',
            visualDensity: VisualDensity.compact,
            onPressed: () => openPrivate(const ChatScreen()),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded),
                if (unreadChatCount > 0)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EmptyState(title: 'Gagal memuat data', subtitle: error, icon: Icons.wifi_off_rounded),
                      FilledButton(onPressed: load, child: const Text('Coba Lagi')),
                    ],
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: SizedBox(
                          height: 44,
                          child: TextField(
                            readOnly: true,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded, size: 20),
                              hintText: 'Cari produk custom...',
                              hintStyle: TextStyle(fontSize: 13.2),
                            ),
                          ),
                        ),
                      ),

                      const PremiumFeatureStrip(),
                      const HomeHeroBanner(),

                      HomeMediaPromoGrid(
                        videos: videos.take(3).toList(),
                        flashSale: flashSale.take(3).toList(),
                        onTapVideoAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoScreen())),
                        onTapFlashAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashSaleScreen())),
                        onTapVideoItem: openVideo,
                        onTapFlashItem: openFlashProduct,
                      ),

                      if (categories.isNotEmpty) ...[
                        const SectionTitle(title: 'Kategori'),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 7),
                            itemBuilder: (_, i) {
                              final cat = Map<String, dynamic>.from(categories[i] as Map);
                              return CategoryChipItem(category: cat);
                            },
                          ),
                        ),
                      ],

                      SectionTitle(
                        title: 'Produk Pilihan',
                        actionText: 'Lihat semua',
                        onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                      ),

                      if (products.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: EmptyState(
                            title: 'Produk belum tersedia',
                            subtitle: 'Produk aktif dari website akan tampil otomatis di sini.',
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 2, 14, 18),
                          itemCount: products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: .72,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemBuilder: (_, i) {
                            final product = Map<String, dynamic>.from(products[i] as Map);

                            return CompactProductCard(
                              product: product,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                              ),
                              onCartTap: () => addCart(product),
                            );
                          },
                        ),
                    ],
                  ),
      ),
    );
  }
}
