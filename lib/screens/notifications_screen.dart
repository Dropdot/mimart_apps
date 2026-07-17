import 'package:flutter/material.dart';

import '../core/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final res = await ApiClient.get('notifications.php');
      final data = res['data'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      setState(() {
        notifications = data['notifications'] as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        notifications = [];
        loading = false;
      });
    }
  }

  Widget card(Map<String, dynamic> n) {
    final title = (n['title'] ?? n['subject'] ?? 'Notifikasi').toString();
    final body = (n['body'] ?? n['message'] ?? n['content'] ?? '').toString();
    final date = (n['created_at'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14, offset: const Offset(0, 7))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_none_rounded, color: Color(0xFF97002B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: Colors.black87)),
                ],
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(date, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ],
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
      appBar: AppBar(title: const Text('Notifikasi')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text('Belum ada notifikasi.'))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: notifications.map((e) => card(Map<String, dynamic>.from(e as Map))).toList(),
                  ),
                ),
    );
  }
}
