import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_gate.dart';
import '../widgets/category_chip.dart';
import '../widgets/compact_product_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_title.dart';
import 'product_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool loading = true;
  List<dynamic> categories = [];
  List<dynamic> products = [];
  String selected = '';

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  String catTitle(Map<String, dynamic> c) {
    return (c['display_name'] ?? c['name'] ?? c['category_name'] ?? c['title'] ?? c['slug'] ?? '').toString();
  }

  Future<void> loadAll() async {
    final cats = await ApiClient.get('categories.php');
    final catData = cats['data'] as Map<String, dynamic>? ?? {};
    categories = catData['categories'] as List<dynamic>? ?? [];
    if (categories.isNotEmpty) {
      selected = catTitle(Map<String, dynamic>.from(categories.first as Map));
    }
    await loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);
    final res = await ApiClient.get('products.php', query: selected.isEmpty ? null : {'category': selected});
    final data = res['data'] as Map<String, dynamic>? ?? {};
    setState(() {
      products = data['products'] as List<dynamic>? ?? [];
      loading = false;
    });
  }

  Future<void> addCart(Map<String, dynamic> product) async {
    final ok = await AuthGate.ensureLogin(context);
    if (!ok) return;
    final res = await ApiClient.post('cart_add.php', body: {'product_id': product['id'], 'quantity': 1});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'Selesai')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Kategori')),
      body: RefreshIndicator(
        onRefresh: loadAll,
        child: ListView(
          children: [
            const SectionTitle(title: 'Pilih Kategori'),
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = Map<String, dynamic>.from(categories[i] as Map);
                  final title = catTitle(cat);
                  return CategoryChipItem(
                    category: cat,
                    selected: title == selected,
                    onTap: () {
                      setState(() => selected = title);
                      loadProducts();
                    },
                  );
                },
              ),
            ),
            SectionTitle(title: selected.isEmpty ? 'Produk' : selected),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (products.isEmpty)
              const EmptyState(title: 'Produk kosong', subtitle: 'Belum ada produk aktif di kategori ini.')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .70,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (_, i) {
                  final product = Map<String, dynamic>.from(products[i] as Map);
                  return CompactProductCard(
                    product: product,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
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
