import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_gate.dart';
import '../widgets/compact_product_card.dart';
import '../widgets/empty_state.dart';
import 'product_detail_screen.dart';

class FlashSaleScreen extends StatefulWidget {
  const FlashSaleScreen({super.key});

  @override
  State<FlashSaleScreen> createState() => _FlashSaleScreenState();
}

class _FlashSaleScreenState extends State<FlashSaleScreen> {
  final controller = ScrollController();
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  String error = '';
  int page = 1;
  final int limit = 20;
  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    controller.addListener(onScroll);
    load(reset: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onScroll() {
    if (controller.position.pixels >= controller.position.maxScrollExtent - 300) {
      loadMore();
    }
  }

  Future<void> load({bool reset = false}) async {
    if (reset) {
      setState(() {
        loading = true;
        error = '';
        page = 1;
        hasMore = true;
        products = [];
      });
    }

    final res = await ApiClient.get('flash_sale.php', query: {'page': page, 'limit': limit});
    final data = res['data'] as Map<String, dynamic>? ?? {};

    if (res['status'] != 'success') {
      setState(() {
        error = res['message']?.toString() ?? 'Gagal memuat flash sale';
        loading = false;
        loadingMore = false;
      });
      return;
    }

    final rows = data['products'] as List<dynamic>? ?? [];

    setState(() {
      products.addAll(rows);
      hasMore = rows.length >= limit;
      loading = false;
      loadingMore = false;
    });
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    setState(() {
      loadingMore = true;
      page++;
    });
    await load();
  }

  Future<void> refresh() async {
    await load(reset: true);
  }

  Future<void> addCart(Map<String, dynamic> product) async {
    final ok = await AuthGate.ensureLogin(context);
    if (!ok) return;

    final res = await ApiClient.post('cart_add.php', body: {'product_id': product['id'], 'quantity': 1});

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message']?.toString() ?? 'Selesai')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Flash Sale')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EmptyState(title: 'Gagal memuat flash sale', subtitle: error),
                      FilledButton(onPressed: refresh, child: const Text('Coba Lagi')),
                    ],
                  )
                : products.isEmpty
                    ? const EmptyState(
                        title: 'Belum ada Flash Sale',
                        subtitle: 'Produk flash sale aktif dari website akan tampil di sini.',
                      )
                    : CustomScrollView(
                        controller: controller,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
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
                                childCount: products.length,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: .72,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                              ),
                            ),
                          ),
                          if (loadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            ),
                        ],
                      ),
      ),
    );
  }
}
