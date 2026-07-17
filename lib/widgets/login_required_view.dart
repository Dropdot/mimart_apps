import 'package:flutter/material.dart';

import '../core/auth_gate.dart';

class LoginRequiredView extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onLoggedIn;

  const LoginRequiredView({
    super.key,
    required this.title,
    required this.subtitle,
    this.onLoggedIn,
  });

  Future<void> _login(BuildContext context) async {
    final ok = await AuthGate.ensureLogin(context);
    if (ok && onLoggedIn != null) onLoggedIn!();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEBD7DD)),
            ),
            child: const Icon(Icons.lock_outline_rounded, size: 40, color: Color(0xFF97002B)),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.35)),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => _login(context),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF97002B), minimumSize: const Size.fromHeight(48)),
            child: const Text('Login Sekarang'),
          ),
        ],
      ),
    );
  }
}
