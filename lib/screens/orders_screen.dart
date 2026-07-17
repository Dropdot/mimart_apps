import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_gate.dart';
import '../core/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/login_required_view.dart';
import '../widgets/mobile_status_chip.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final String initialFilter;

  const OrdersScreen({
    super.key,
    this.initialFilter = 'all',
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool loading = true;
  bool loggedIn = false;
  List<dynamic> orders = [];

  late String activeFilter;

  final List<Map<String, String>> filters = const [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'pending_payment', 'label': 'Belum Bayar'},
    {'key': 'waiting_review', 'label': 'Verifikasi'},
    {'key': 'payment_success', 'label': 'Dibayar'},
    {'key': 'processing', 'label': 'Diproses'},
    {'key': 'ready_to_ship', 'label': 'Siap Kirim'},
    {'key': 'completed', 'label': 'Selesai'},
  ];

  @override
  void initState() {
    super.initState();
    activeFilter = widget.initialFilter;
    load();
  }

  bool ok(Map<String, dynamic> res) {
    return res['success'] == true || res['status'] == 'success' || res['ok'] == true;
  }

  Future<void> load() async {
    final isLogin = await AuthGate.isLoggedIn();

    if (!isLogin) {
      if (!mounted) return;
      setState(() {
        loggedIn = false;
        loading = false;
      });
      return;
    }

    if (mounted) setState(() => loading = true);

    try {
      final res = await ApiClient.get(
        'orders.php',
        query: {'filter': activeFilter},
      );

      final data = res['data'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      setState(() {
        loggedIn = true;
        orders = data['orders'] as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loggedIn = true;
        orders = [];
        loading = false;
      });
    }
  }

  String rawStatus(Map<String, dynamic> order) {
    return (order['order_status'] ?? order['status'] ?? '-').toString();
  }

  String statusLabel(String value) {
    switch (value) {
      case 'pending_payment':
        return 'Belum Bayar';
      case 'waiting_review':
        return 'Verifikasi';
      case 'payment_success':
      case 'paid':
        return 'Dibayar';
      case 'processing':
      case 'process_design':
      case 'revision':
      case 'printing':
        return 'Diproses';
      case 'ready_to_ship':
      case 'shipped':
        return 'Siap Kirim';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return value;
    }
  }

  Future<void> changeFilter(String filter) async {
    if (activeFilter == filter) return;
    setState(() => activeFilter = filter);
    await load();
  }

  Widget filterChips() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = filters[i];
          final key = item['key'] ?? 'all';
          final label = item['label'] ?? 'Semua';
          final selected = activeFilter == key;

          return ChoiceChip(
            selected: selected,
            label: Text(label),
            onSelected: (_) => changeFilter(key),
            selectedColor: const Color(0xFF97002B),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            side: BorderSide(
              color: selected ? const Color(0xFF97002B) : const Color(0xFFEBD7DD),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          );
        },
      ),
    );
  }

  Widget orderCard(Map<String, dynamic> order) {
    final code = (order['order_code'] ?? '#${order['id'] ?? '-'}').toString();
    final createdAt = (order['created_at'] ?? '').toString();
    final total = order['grand_total'] ?? order['total'] ?? order['total_amount'] ?? 0;
    final status = rawStatus(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                    MobileStatusChip(label: statusLabel(status)),
                  ],
                ),
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(createdAt, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Formatters.rupiah(total),
                        style: const TextStyle(
                          color: Color(0xFF97002B),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(title: const Text('Pesanan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!loggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(title: const Text('Pesanan')),
        body: LoginRequiredView(
          title: 'Login untuk melihat pesanan',
          subtitle: 'Riwayat pesanan terhubung dengan akun customer kamu.',
          onLoggedIn: load,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Pesanan')),
      body: Column(
        children: [
          filterChips(),
          Expanded(
            child: orders.isEmpty
                ? const EmptyState(
                    title: 'Belum ada pesanan',
                    subtitle: 'Pesanan sesuai filter ini belum tersedia.',
                    icon: Icons.receipt_long_outlined,
                  )
                : RefreshIndicator(
                    onRefresh: load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      itemCount: orders.length,
                      itemBuilder: (_, i) {
                        final order = Map<String, dynamic>.from(orders[i] as Map);
                        return orderCard(order);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
