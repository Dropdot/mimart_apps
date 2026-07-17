import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;
  final dynamic productId;
  final dynamic id;
  final String? slug;

  const ProductDetailScreen({
    super.key,
    this.product,
    this.productId,
    this.id,
    this.slug,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool loading = true;
  bool addingCart = false;
  bool favoriteLoading = false;
  bool isFavorite = false;

  Map<String, dynamic> product = {};
  List<dynamic> variants = [];
  Map<String, dynamic>? selectedVariant;
  List<String> images = [];

  int imageIndex = 0;
  int qty = 1;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  int productIdFromInput() {
    final direct = int.tryParse('${widget.productId ?? widget.id ?? ''}');
    if (direct != null && direct > 0) return direct;

    final p = widget.product;
    if (p is Map) {
      final fromProduct = int.tryParse('${p['id'] ?? p['product_id'] ?? ''}');
      if (fromProduct != null && fromProduct > 0) return fromProduct;
    }
    return 0;
  }

  String slugFromInput() {
    if ((widget.slug ?? '').trim().isNotEmpty) return widget.slug!.trim();
    final p = widget.product;
    if (p is Map) return (p['slug'] ?? '').toString().trim();
    return '';
  }

  Map<String, dynamic> dataOrRoot(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return res;
  }

  bool ok(Map<String, dynamic> res) => res['success'] == true || res['status'] == 'success' || res['ok'] == true;

  List<String> normalizeImages(Map<String, dynamic> data, Map<String, dynamic> loadedProduct) {
    final result = <String>[];
    final seen = <String>{};
    void add(dynamic value) {
      final text = (value ?? '').toString().trim();
      if (text.isEmpty) return;
      final key = text.toLowerCase();
      if (seen.contains(key)) return;
      seen.add(key);
      result.add(text);
    }

    final productImages = loadedProduct['image_urls'] ?? loadedProduct['gallery'];
    final rootGallery = data['gallery'];
    if (productImages is List) {
      for (final item in productImages) add(item);
    }
    if (rootGallery is List) {
      for (final item in rootGallery) add(item);
    }
    add(loadedProduct['image_url']);
    return result;
  }

  String rupiah(dynamic value) {
    final number = double.tryParse('$value') ?? 0;
    final rounded = number.round();
    final text = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final left = text.length - i;
      buffer.write(text[i]);
      if (left > 1 && left % 3 == 1) buffer.write('.');
    }
    return 'Rp${buffer.toString()}';
  }

  Future<void> loadDetail() async {
    setState(() => loading = true);
    try {
      final id = productIdFromInput();
      final slug = slugFromInput();
      final query = <String, String>{};
      if (id > 0) query['id'] = '$id';
      if (id <= 0 && slug.isNotEmpty) query['slug'] = slug;

      final res = await ApiClient.get('product_detail.php', query: query);
      final data = dataOrRoot(res);
      final loadedProduct = Map<String, dynamic>.from(data['product'] as Map? ?? {});
      final loadedVariants = data['variants'] as List<dynamic>? ?? loadedProduct['variants'] as List<dynamic>? ?? [];
      final gallery = normalizeImages(data, loadedProduct);

      if (!mounted) return;
      setState(() {
        product = loadedProduct;
        variants = loadedVariants;
        selectedVariant = loadedVariants.isNotEmpty ? Map<String, dynamic>.from(loadedVariants.first as Map) : null;
        images = gallery;
        imageIndex = 0;
        isFavorite = loadedProduct['is_favorite'] == true;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat detail produk: $e')));
    }
  }

  dynamic activePrice() => selectedVariant != null
      ? selectedVariant!['price'] ?? product['display_price'] ?? product['price'] ?? product['base_price'] ?? 0
      : product['display_price'] ?? product['price'] ?? product['base_price'] ?? 0;

  dynamic activeStrikePrice() => selectedVariant != null
      ? selectedVariant!['strike_price'] ?? product['display_strike_price'] ?? product['strike_price'] ?? 0
      : product['display_strike_price'] ?? product['strike_price'] ?? 0;

  String activeVariantName() => selectedVariant == null ? '' : (selectedVariant!['variant_name'] ?? selectedVariant!['name'] ?? '').toString();

  int activeStock() => selectedVariant == null ? 999999 : int.tryParse('${selectedVariant!['stock'] ?? 0}') ?? 0;

  Future<bool> addToCart() async {
    if (product.isEmpty) return false;
    if (variants.isNotEmpty && selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih varian produk dulu.')));
      return false;
    }
    if (selectedVariant != null && activeStock() <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok varian ini habis.')));
      return false;
    }

    setState(() => addingCart = true);
    try {
      final res = await ApiClient.post('cart_add.php', body: {
        'product_id': product['id'],
        'variant_id': selectedVariant?['id'],
        'quantity': qty,
      });

      if (!mounted) return false;
      if (ok(res)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(selectedVariant == null ? 'Produk berhasil masuk keranjang.' : '${activeVariantName()} masuk keranjang dengan harga ${rupiah(activePrice())}.')),
        );
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((res['message'] ?? 'Gagal menambahkan ke keranjang.').toString())));
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambahkan ke keranjang: $e')));
      return false;
    } finally {
      if (mounted) setState(() => addingCart = false);
    }
  }

  Future<void> buyNow() async {
    final added = await addToCart();
    if (!mounted || !added) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()));
  }

  Future<void> toggleFavorite() async {
    if (product.isEmpty || favoriteLoading) return;
    setState(() => favoriteLoading = true);
    try {
      final res = await ApiClient.post('favorite_toggle.php', body: {'product_id': product['id']});
      if (!mounted) return;
      if (ok(res)) {
        final data = dataOrRoot(res);
        setState(() => isFavorite = data['is_favorite'] == true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFavorite ? 'Produk ditambahkan ke favorit.' : 'Produk dihapus dari favorit.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((res['message'] ?? 'Gagal memproses favorit.').toString())));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memproses favorit: $e')));
    } finally {
      if (mounted) setState(() => favoriteLoading = false);
    }
  }

  double galleryHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final calculated = width * 0.78;
    if (calculated < 280) return 280;
    if (calculated > 360) return 360;
    return calculated;
  }

  Widget galleryFrame({required Widget child}) {
    return Container(width: double.infinity, height: galleryHeight(context), color: Colors.white, child: Center(child: child));
  }

  Widget galleryImage(String url) {
    return galleryFrame(
      child: Image.network(
        url,
        width: double.infinity,
        height: galleryHeight(context),
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 56, color: Colors.black38)),
        loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Widget imageCarousel() {
    if (images.isEmpty) return galleryFrame(child: const Icon(Icons.image_outlined, size: 56, color: Colors.black38));
    return Container(
      width: double.infinity,
      height: galleryHeight(context),
      color: Colors.white,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) => setState(() => imageIndex = index),
            itemBuilder: (_, index) => galleryImage(images[index]),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: Colors.black.withOpacity(.48), borderRadius: BorderRadius.circular(999)),
              child: Text('${imageIndex + 1} / ${images.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget priceBlock() {
    final price = activePrice();
    final strike = double.tryParse('${activeStrikePrice()}') ?? 0;
    final priceNum = double.tryParse('$price') ?? 0;
    final variantName = activeVariantName();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: const [
            _Badge(icon: Icons.workspace_premium_outlined, text: 'Produk Premium'),
            _Badge(icon: Icons.local_offer_outlined, text: 'Harga Varian'),
          ]),
          const SizedBox(height: 12),
          Text((product['product_name'] ?? product['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, height: 1.20)),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 3),
              Text('${product['rating'] ?? 5}', style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
              if (variantName.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Flexible(child: Text(variantName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF97002B), fontWeight: FontWeight.w800))),
              ],
            ],
          ),
          const SizedBox(height: 9),
          if (strike > priceNum) Text(rupiah(strike), style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black38, fontSize: 13)),
          Text(rupiah(price), style: const TextStyle(color: Color(0xFF97002B), fontWeight: FontWeight.w900, fontSize: 24)),
          if (selectedVariant != null) ...[
            const SizedBox(height: 4),
            Text('Harga mengikuti varian: $variantName', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget variantBlock() {
    if (variants.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilihan Varian', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 10),
          ...variants.map((raw) {
            final variant = Map<String, dynamic>.from(raw as Map);
            final isSelected = '${selectedVariant?['id']}' == '${variant['id']}';
            final stock = int.tryParse('${variant['stock'] ?? 0}') ?? 0;
            final disabled = stock <= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected ? const Color(0xFFFFEEF2) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: disabled ? null : () => setState(() => selectedVariant = variant),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF97002B) : const Color(0xFFE5E7EB), width: isSelected ? 1.4 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: disabled ? Colors.black26 : isSelected ? const Color(0xFF97002B) : Colors.black38),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((variant['variant_name'] ?? variant['name'] ?? '').toString(), style: TextStyle(fontWeight: FontWeight.w900, color: disabled ? Colors.black38 : const Color(0xFF111827))),
                            const SizedBox(height: 3),
                            Text(disabled ? 'Stok habis' : 'Stok: $stock', style: TextStyle(color: disabled ? Colors.red.shade300 : Colors.black45, fontSize: 12)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          if ((double.tryParse('${variant['strike_price'] ?? 0}') ?? 0) > (double.tryParse('${variant['price'] ?? 0}') ?? 0))
                            Text(rupiah(variant['strike_price']), style: const TextStyle(color: Colors.black38, fontSize: 11, decoration: TextDecoration.lineThrough)),
                          Text(rupiah(variant['price']), style: TextStyle(color: disabled ? Colors.black38 : const Color(0xFF97002B), fontWeight: FontWeight.w900)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget descriptionBlock() {
    final description = (product['description'] ?? '').toString();
    if (description.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Text(description, style: const TextStyle(color: Color(0xFF374151), height: 1.45, fontSize: 13)),
    );
  }

  Widget bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -4))]),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: OutlinedButton(
                onPressed: favoriteLoading ? null : toggleFavorite,
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: const BorderSide(color: Color(0xFFE5E7EB)), foregroundColor: const Color(0xFF97002B)),
                child: favoriteLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: addingCart ? null : addToCart,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF97002B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: addingCart ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Keranjang', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: addingCart ? null : buyNow,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF820026), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: const Text('Beli', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: Color(0xFFF7F8FC), body: Center(child: CircularProgressIndicator()));
    if (product.isEmpty) return Scaffold(appBar: AppBar(title: const Text('Detail Produk')), body: const Center(child: Text('Produk tidak ditemukan.')));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: const Color(0xFF97002B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: favoriteLoading ? null : toggleFavorite, icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded)),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          imageCarousel(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            child: Column(children: [priceBlock(), variantBlock(), descriptionBlock()]),
          ),
        ],
      ),
      bottomNavigationBar: bottomBar(),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Badge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFFEEF2), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFF8B4C4))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF97002B), size: 14),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Color(0xFF97002B), fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}
