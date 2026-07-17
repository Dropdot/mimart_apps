import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_gate.dart';
import '../core/auth_storage.dart';
import 'address_list_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'help_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'video_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  bool loggedIn = false;

  Map<String, dynamic> profile = {};
  Map<String, dynamic> badges = {};

  @override
  void initState() {
    super.initState();
    loadAccount();
  }

  Future<void> loadAccount() async {
    final token = await AuthStorage.token();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loggedIn = false;
        profile = {};
        badges = {};
      });
      return;
    }

    try {
      final res = await ApiClient.get('account_summary.php');
      final data = res['data'];

      Map<String, dynamic> nextProfile = {};
      Map<String, dynamic> nextBadges = {};

      if (data is Map<String, dynamic>) {
        if (data['user_profile'] is Map) {
          nextProfile = Map<String, dynamic>.from(data['user_profile'] as Map);
        }

        if (data['order_badges'] is Map) {
          nextBadges = Map<String, dynamic>.from(data['order_badges'] as Map);
        }
      }

      if (!mounted) return;

      setState(() {
        loading = false;
        loggedIn = true;
        profile = nextProfile;
        badges = nextBadges;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        loggedIn = true;
        profile = {};
        badges = {};
      });
    }
  }

  Future<void> goLogin() async {
    final ok = await AuthGate.ensureLogin(context);
    if (ok) await loadAccount();
  }

  Future<void> logout() async {
    try {
      await ApiClient.post('logout.php');
    } catch (_) {}

    await AuthStorage.clear();

    if (!mounted) return;

    setState(() {
      loggedIn = false;
      profile = {};
      badges = {};
    });
  }

  String valueOf(List<dynamic> values, String fallback) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String get name => valueOf(
        [
          profile['name'],
          profile['full_name'],
          profile['nama'],
          profile['username'],
          profile['email'],
        ],
        'MI MART Customer',
      );

  String get username => valueOf([profile['username']], 'user');

  String get email => valueOf([profile['email']], '');

  String get membership => valueOf([profile['membership']], 'Basic Member');

  String get avatarUrl => valueOf(
        [
          profile['avatar_direct_url'],
          profile['avatar_url'],
          profile['avatar'],
          profile['avatar_proxy_url'],
        ],
        '',
      );

  String get initial {
    final clean = name.trim();
    if (clean.isEmpty) return 'M';
    return clean.substring(0, 1).toUpperCase();
  }

  int badge(String key) {
    final value = badges[key];
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  String badgeText(String key) {
    final count = badge(key);
    if (count <= 0) return '';
    return count > 99 ? '99+' : '$count';
  }

  Widget avatarWidget() {
    Widget fallback() {
      return CircleAvatar(
        radius: 30,
        backgroundColor: const Color(0xFFFFEEF2),
        child: Text(
          initial,
          style: const TextStyle(
            color: Color(0xFF97002B),
            fontWeight: FontWeight.w900,
            fontSize: 23,
          ),
        ),
      );
    }

    if (avatarUrl.isEmpty) return fallback();

    return ClipOval(
      child: Container(
        width: 60,
        height: 60,
        color: const Color(0xFFFFEEF2),
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, __, ___) {
            final proxy = (profile['avatar_proxy_url'] ?? '').toString().trim();

            if (proxy.isNotEmpty && proxy != avatarUrl) {
              return Image.network(
                proxy,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF97002B),
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF97002B),
                  fontWeight: FontWeight.w900,
                  fontSize: 23,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget loginView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Akun')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF97002B), Color(0xFF6F001F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_outline_rounded, color: Colors.white, size: 36),
                SizedBox(height: 28),
                Text(
                  'Masuk ke MI MART',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Kelola pesanan, alamat, chat, pembayaran, dan notifikasi Anda.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: goLogin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF97002B),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Login / Register'),
          ),
        ],
      ),
    );
  }

  Widget profileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          avatarWidget(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email.isNotEmpty ? email : '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEF2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '@$username',
                        style: const TextStyle(
                          color: Color(0xFF97002B),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        membership,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget badgeDot(String key) {
    final text = badgeText(key);

    if (text.isEmpty) return const SizedBox.shrink();

    return Positioned(
      right: -10,
      top: -8,
      child: Container(
        constraints: const BoxConstraints(minWidth: 17),
        height: 17,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 1.4),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget orderStatusItem({
    required IconData icon,
    required String label,
    required String keyName,
    required String filter,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrdersScreen(initialFilter: filter)),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const SizedBox(width: 24, height: 23),
                  Positioned.fill(
                    child: Icon(
                      icon,
                      size: 22,
                      color: const Color(0xFF97002B),
                    ),
                  ),
                  badgeDot(keyName),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget ordersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pesanan Saya',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                },
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Lihat Riwayat Pesanan ›',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.55,
            children: [
              orderStatusItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Belum Bayar',
                keyName: 'pending_payment',
                filter: 'pending_payment',
              ),
              orderStatusItem(
                icon: Icons.access_time_rounded,
                label: 'Verifikasi',
                keyName: 'waiting_review',
                filter: 'waiting_review',
              ),
              orderStatusItem(
                icon: Icons.check_circle_outline_rounded,
                label: 'Dibayar',
                keyName: 'payment_success',
                filter: 'payment_success',
              ),
              orderStatusItem(
                icon: Icons.settings_outlined,
                label: 'Diproses',
                keyName: 'processing',
                filter: 'processing',
              ),
              orderStatusItem(
                icon: Icons.local_shipping_outlined,
                label: 'Siap Kirim',
                keyName: 'ready_to_ship',
                filter: 'ready_to_ship',
              ),
              orderStatusItem(
                icon: Icons.flag_circle_outlined,
                label: 'Selesai',
                keyName: 'completed',
                filter: 'completed',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF97002B),
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }

  Widget divider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: Color(0xFFF1E4E8),
    );
  }

  Widget menuCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.white,
        child: Column(children: children),
      ),
    );
  }

  Widget linkedMenu(IconData icon, String title, Widget page) {
    return menuItem(
      icon: icon,
      title: title,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ).then((_) => loadAccount());
      },
    );
  }

  Widget loggedInView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Akun')),
      body: RefreshIndicator(
        onRefresh: loadAccount,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            profileCard(),
            const SizedBox(height: 12),
            ordersCard(),
            const SizedBox(height: 12),
            menuCard([
              linkedMenu(Icons.person_outline_rounded, 'Edit Profil', const EditProfileScreen()),
              divider(),
              linkedMenu(Icons.lock_outline_rounded, 'Ganti Password', const ChangePasswordScreen()),
              divider(),
              linkedMenu(Icons.location_on_outlined, 'Alamat', const AddressListScreen()),
              divider(),
              linkedMenu(Icons.favorite_border_rounded, 'Favorite', const FavoritesScreen()),
              divider(),
              linkedMenu(Icons.notifications_none_rounded, 'Notifikasi', const NotificationsScreen()),
              divider(),
              linkedMenu(Icons.video_library_outlined, 'MI MART TV', const VideoScreen()),
              divider(),
              linkedMenu(Icons.help_outline_rounded, 'Bantuan', const HelpScreen()),
              divider(),
              menuItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                color: const Color(0xFFE11D48),
                onTap: logout,
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(title: const Text('Akun')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!loggedIn) return loginView();

    return loggedInView();
  }
}
