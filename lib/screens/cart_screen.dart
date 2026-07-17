import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/formatters.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onCartChanged;

  const CartScreen({
    super.key,
    this.onCartChanged,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool loading = true;
  bool removing = false;
  List<dynamic> items = [];
  num total = 0;
  int totalQty = 0;

  static const maroon = Color(0xFF97002B);
  static const darkMaroon = Color(0xFF820026);
  static const bg = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    load();
  }

  Map<String, dynamic> dataOrRoot(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return res;
  }

  bool ok(Map<String, dynamic> res) {
    return res['success'] == true || res['status'] == 'success' || res['ok'] == true;
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final res = await ApiClient.get('cart.php');
      final data = dataOrRoot(res);

      if (!mounted) return;

      setState(() {
        items = data['items'] as List<dynamic>? ?? data['cart_items'] as List<dynamic>? ?? [];
        total = num.tryParse('${data['grand_total'] ?? data['total'] ?? data['subtotal'] ?? 0}') ?? 0;
        totalQty = int.tryParse('${data['total_qty'] ?? 0}') ?? 0;
        if (totalQty <= 0) {
          totalQty = items.fold<int>(0, (sum, item) {
            final map = Map<String, dynamic>.from(item as Map);
            return sum + (int.tryParse('${map['quantity'] ?? map['qty'] ?? 1}') ?? 1);
          });
        }
        loading = false;
      });

      widget.onCartChanged?.call();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        items = [];
        total = 0;
        totalQty = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat keranjang: $e')),
      );
    }
  }

  Future<void> removeItem(Map<String, dynamic> item) async {
    final id = item['id'] ?? item['cart_id'];
    if (id == null || removing) return;

    setState(() => removing = true);

    try {
      final res = await ApiClient.post(
        'cart_remove.php',
        body: {'id': id},
      );

      if (!mounted) return;

      if (ok(res)) {
        await load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item dihapus dari keranjang.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((res['message'] ?? 'Gagal menghapus item.').toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus item: $e')),
      );
    } finally {
      if (mounted) setState(() => removing = false);
    }
  }

  String itemName(Map<String, dynamic> item) {
    return (item['product_name'] ?? item['name'] ?? '-').toString();
  }

  String variantName(Map<String, dynamic> item) {
    return (item['variant_name'] ?? item['selected_variant_name'] ?? '').toString().trim();
  }

  int itemQty(Map<String, dynamic> item) {
    return int.tryParse('${item['quantity'] ?? item['qty'] ?? 1}') ?? 1;
  }

  num itemPrice(Map<String, dynamic> item) {
    return num.tryParse('${item['selected_price'] ?? item['price'] ?? 0}') ?? 0;
  }

  num itemSubtotal(Map<String, dynamic> item) {
    final subtotal = num.tryParse('${item['subtotal'] ?? 0}') ?? 0;
    if (subtotal > 0) return subtotal;
    return itemPrice(item) * itemQty(item);
  }

  String imageUrl(Map<String, dynamic> item) {
    return (item['image_url'] ?? '').toString().trim();
  }

  Widget imageBox(Map<String, dynamic> item) {
    final url = imageUrl(item);

    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5D0DA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const Icon(Icons.shopping_bag_outlined, color: maroon, size: 30)
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: maroon, size: 30),
            ),
    );
  }

  Widget cartItem(Map<String, dynamic> item) {
    final name = itemName(item);
    final variant = variantName(item);
    final qty = itemQty(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1E5EA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageBox(item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    height: 1.20,
                  ),
                ),
                if (variant.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEF2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      variant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: maroon,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        'Qty $qty',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.rupiah(itemSubtotal(item)),
                      style: const TextStyle(
                        color: maroon,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: removing ? null : () => removeItem(item),
              icon: const Icon(Icons.delete_outline_rounded),
              color: maroon,
              padding: EdgeInsets.zero,
              tooltip: 'Hapus',
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, -6)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF8B4C4)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalQty item',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      Formatters.rupiah(total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: maroon,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 54,
              width: 162,
              child: FilledButton(
                onPressed: items.isEmpty
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        );
                        if (mounted) load();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: maroon,
                  disabledBackgroundColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyState() {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 130, 24, 24),
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEEF2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined, size: 44, color: maroon),
          ),
          const SizedBox(height: 18),
          const Text(
            'Keranjang masih kosong',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Produk yang kamu tambahkan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), height: 1.35),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Keranjang'),
        backgroundColor: maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: maroon))
          : items.isEmpty
              ? emptyState()
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 118),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [maroon, darkMaroon],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Siap checkout?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$totalQty item ada di keranjangmu',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(.82),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...items.map((raw) => cartItem(Map<String, dynamic>.from(raw as Map))),
                    ],
                  ),
                ),
      bottomNavigationBar: items.isEmpty || loading ? null : summaryBar(context),
    );
  }
}
