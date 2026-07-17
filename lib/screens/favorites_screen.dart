import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/formatters.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool loading = true;
  List<dynamic> favorites = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final res = await ApiClient.get('favorites.php');
      final data = res['data'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      setState(() {
        favorites = data['favorites'] as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        favorites = [];
        loading = false;
      });
    }
  }

  String name(Map<String, dynamic> f) {
    return (f['product_name'] ?? f['name'] ?? 'Produk').toString();
  }

  dynamic price(Map<String, dynamic> f) {
    return f['base_price'] ?? f['price'] ?? 0;
  }

  Widget card(Map<String, dynamic> f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14, offset: const Offset(0, 7))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFF97002B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name(f), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(Formatters.rupiah(price(f)), style: const TextStyle(color: Color(0xFF97002B), fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Favorite')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? const Center(child: Text('Belum ada produk favorit.'))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: favorites.map((e) => card(Map<String, dynamic>.from(e as Map))).toList(),
                  ),
                ),
    );
  }
}
