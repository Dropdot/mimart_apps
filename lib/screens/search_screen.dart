import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/auth_gate.dart';
import '../widgets/compact_product_card.dart';
import '../widgets/empty_state.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController query;
  Timer? debounce;
  bool loading = false;
  List<dynamic> products = [];
  String error = '';

  @override
  void initState() {
    super.initState();
    query = TextEditingController(text: widget.initialQuery);
    load();
  }

  @override
  void dispose() {
    debounce?.cancel();
    query.dispose();
    super.dispose();
  }

  void onTyping(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 420), load);
  }

  Future<void> load() async {
    setState(() { loading = true; error = ''; });
    final res = await ApiClient.get('product_search.php', query: {'q': query.text.trim()});
    final data = res['data'] as Map<String, dynamic>? ?? {};

    if (res['status'] != 'success') {
      setState(() {
        error = res['message']?.toString() ?? 'Pencarian gagal';
        products = [];
        loading = false;
      });
      return;
    }

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
    final hasQuery = query.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Cari Produk')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: onTyping,
                onSubmitted: (_) => load(),
                decoration: InputDecoration(
                  hintText: 'Ketik nama produk...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: query.text.isEmpty
                      ? IconButton(onPressed: load, icon: const Icon(Icons.arrow_forward_rounded), visualDensity: VisualDensity.compact)
                      : IconButton(onPressed: () { query.clear(); load(); }, icon: const Icon(Icons.close_rounded), visualDensity: VisualDensity.compact),
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                    ? EmptyState(title: 'Pencarian gagal', subtitle: error, icon: Icons.wifi_off_rounded)
                    : products.isEmpty
                        ? EmptyState(
                            title: hasQuery ? 'Produk tidak ditemukan' : 'Cari produk MI MART',
                            subtitle: hasQuery ? 'Coba kata kunci lain atau cek penulisan produk.' : 'Ketik nama produk, kategori, atau kata kunci custom.',
                            icon: Icons.search_off_rounded,
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
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
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                                onCartTap: () => addCart(product),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
