import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_storage.dart';
import '../core/fcm_service.dart';
import '../widgets/custom_button.dart';
import 'main_shell_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool returnToHome;

  const LoginScreen({super.key, this.returnToHome = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final identity = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    identity.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (identity.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username/email dan password wajib diisi')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await ApiClient.post(
        'login.php',
        body: {
          'identity': identity.text.trim(),
          'password': password.text,
          'platform': 'android',
        },
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        final token = res['data']?['token']?.toString() ?? '';

        if (token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token login kosong dari server')),
          );
          return;
        }

        await AuthStorage.saveToken(token);
        await FcmService.syncTokenToBackend();

        if (!mounted) return;

        if (widget.returnToHome) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainShellScreen()),
            (_) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Login gagal')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.returnToHome ? AppBar(title: const Text('Login')) : null,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 70),
          const Text(
            'MI MART',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF800020),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: identity,
            decoration: const InputDecoration(labelText: 'Username / Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: hidePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => hidePassword = !hidePassword),
                icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(text: 'Login', loading: loading, onPressed: login),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}
