import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/auth_storage.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageC = TextEditingController();
  final ScrollController scrollC = ScrollController();

  bool loading = true;
  bool sending = false;

  int? threadId;
  List<dynamic> messages = [];
  List<dynamic> quickReplies = [];

  Timer? refreshTimer;

  static const maroon = Color(0xFF97002B);
  static const darkMaroon = Color(0xFF820026);
  static const bg = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    loadChat(initial: true);
    refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && !sending) loadChat(silent: true);
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    messageC.dispose();
    scrollC.dispose();
    super.dispose();
  }

  Map<String, dynamic> dataOrRoot(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return res;
  }

  bool ok(Map<String, dynamic> res) {
    return res['success'] == true || res['status'] == 'success' || res['ok'] == true;
  }

  Future<void> loadChat({bool initial = false, bool silent = false}) async {
    if (!silent) setState(() => loading = true);
    try {
      final res = await ApiClient.get('chat_thread.php');
      final data = dataOrRoot(res);

      if (!mounted) return;

      // Ambil pesan dari server, lalu filter pesan template welcome yang tidak diperlukan
      final rawMessages = data['messages'] as List<dynamic>? ?? [];
      final filtered = <dynamic>[];

      for (final item in rawMessages) {
        final msg = Map<String, dynamic>.from(item as Map);
        final txt = (msg['message'] ?? msg['text'] ?? '').toString().toLowerCase();
        final role = (msg['sender_role'] ?? msg['sender_type'] ?? '').toString().toLowerCase();

        // Buang pesan bot pembuka yang mengandung frasa template umum
        if (role == 'bot' && txt.contains('terima kasih') && txt.contains('mi mart')) {
          continue;
        }

        filtered.add(msg);
      }

      setState(() {
        threadId = int.tryParse('${data['thread_id'] ?? (data['thread'] is Map ? data['thread']['id'] : '')}');
        messages = filtered;
        quickReplies = data['quick_replies'] as List<dynamic>? ?? [];
        loading = false;
      });

      if (initial || !silent) scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat chat: $e')),
        );
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollC.hasClients) return;
      scrollC.animateTo(
        scrollC.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> sendText([String? override]) async {
    final text = (override ?? messageC.text).trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);

    try {
      final res = await ApiClient.post(
        'chat_send.php',
        body: {
          'thread_id': threadId,
          'message': text,
        },
      );

      if (!mounted) return;

      if (ok(res)) {
        messageC.clear();
        final data = dataOrRoot(res);
        setState(() {
          threadId = int.tryParse('${data['thread_id'] ?? threadId}');
          messages = data['messages'] as List<dynamic>? ?? messages;
        });
        scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((res['message'] ?? 'Gagal mengirim pesan.').toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> pickAndSendFile() async {
    if (sending) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx', 'xls', 'xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File tidak terbaca. Pilih file lain.')),
      );
      return;
    }

    setState(() => sending = true);

    try {
      final token = await AuthStorage.token();
      final uri = Uri.parse('${AppConfig.baseUrl}/chat_send.php');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['thread_id'] = '${threadId ?? ''}';
      request.fields['message'] = messageC.text.trim();
      request.files.add(http.MultipartFile.fromBytes('attachment', bytes, filename: file.name));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      Map<String, dynamic> body;
      try {
        final decoded = jsonDecode(response.body);
        body = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'success': false, 'message': 'Response server tidak valid.'};
      } catch (_) {
        body = <String, dynamic>{'success': false, 'message': response.body};
      }

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300 && ok(body)) {
        messageC.clear();
        final data = dataOrRoot(body);
        setState(() {
          threadId = int.tryParse('${data['thread_id'] ?? threadId}');
          messages = data['messages'] as List<dynamic>? ?? messages;
        });
        scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((body['message'] ?? 'Gagal upload lampiran chat.').toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload lampiran chat: $e')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  bool isMine(Map<String, dynamic> msg) {
    final explicit = msg['is_mine'];
    if (explicit == true) return true;
    final role = (msg['sender_role'] ?? msg['sender_type'] ?? '').toString().toLowerCase();
    return role == 'user' || role == 'customer' || role == 'buyer';
  }

  String messageText(Map<String, dynamic> msg) {
    return (msg['message'] ?? msg['text'] ?? '').toString();
  }

  String attachmentUrl(Map<String, dynamic> msg) {
    return (msg['attachment_url'] ?? '').toString();
  }

  String attachmentName(Map<String, dynamic> msg) {
    final name = (msg['attachment_name'] ?? '').toString();
    if (name.trim().isNotEmpty) return name;

    final path = (msg['attachment_path'] ?? '').toString();
    if (path.contains('/')) return path.split('/').last;
    return path;
  }

  bool isImageAttachment(Map<String, dynamic> msg) {
    final type = (msg['attachment_type'] ?? '').toString().toLowerCase();
    final name = attachmentName(msg).toLowerCase();
    return type.startsWith('image/') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp');
  }

  Widget headerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [maroon, darkMaroon], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CS MI MART', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 3),
              Text(
                'Kirim pesan, komplain, atau lampiran bukti transaksi.',
                style: TextStyle(color: Colors.white.withOpacity(.82), fontSize: 12.5, height: 1.25),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget quickReplyList() {
    if (quickReplies.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final item = Map<String, dynamic>.from(quickReplies[index] as Map);
          final text = (item['text'] ?? '').toString();

          return ActionChip(
            label: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: maroon)),
            backgroundColor: const Color(0xFFFFEEF2),
            side: const BorderSide(color: Color(0xFFF8B4C4)),
            onPressed: () => sendText(text),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: quickReplies.length,
      ),
    );
  }

  Widget attachmentFileTile(String name, bool mine) {
    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: mine ? Colors.white.withOpacity(.12) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mine ? Colors.white.withOpacity(.16) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file_rounded, size: 18, color: mine ? Colors.white : maroon),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name.isEmpty ? 'Lampiran' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: mine ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget attachmentBubble(Map<String, dynamic> msg, bool mine) {
    final url = attachmentUrl(msg);
    if (url.isEmpty) return const SizedBox.shrink();

    final name = attachmentName(msg);

    if (isImageAttachment(msg)) {
      return Container(
        margin: const EdgeInsets.only(top: 7),
        constraints: const BoxConstraints(maxWidth: 230, maxHeight: 230),
        decoration: BoxDecoration(
          color: mine ? Colors.white.withOpacity(.12) : const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => attachmentFileTile(name, mine),
        ),
      );
    }

    return attachmentFileTile(name, mine);
  }

  Widget messageBubble(Map<String, dynamic> msg) {
    final mine = isMine(msg);
    final text = messageText(msg);
    final created = (msg['created_at'] ?? '').toString();

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? maroon : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 5),
            bottomRight: Radius.circular(mine ? 5 : 18),
          ),
          border: mine ? null : Border.all(color: const Color(0xFFEFE2E7)),
          boxShadow: mine ? [] : [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine) const Text('CS MI MART', style: TextStyle(color: maroon, fontWeight: FontWeight.w900, fontSize: 11.5)),
            if (text.isNotEmpty) ...[
              if (!mine) const SizedBox(height: 3),
              Text(text, style: TextStyle(color: mine ? Colors.white : const Color(0xFF111827), fontSize: 13.5, height: 1.35)),
            ],
            attachmentBubble(msg, mine),
            if (created.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(created, style: TextStyle(color: mine ? Colors.white.withOpacity(.65) : Colors.black38, fontSize: 10.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget emptyState() {
    return Expanded(
      child: ListView(
        controller: scrollC,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          headerCard(),
          const SizedBox(height: 90),
          const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.black26),
          const SizedBox(height: 14),
          const Text('Belum ada percakapan', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 6),
          const Text('Mulai chat dengan CS MI MART.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget messageList() {
    if (messages.isEmpty) return emptyState();

    return Expanded(
      child: ListView.builder(
        controller: scrollC,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 14),
        itemCount: messages.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) {
            return Column(children: [headerCard(), quickReplyList(), const SizedBox(height: 8)]);
          }

          final msg = Map<String, dynamic>.from(messages[index - 1] as Map);
          return messageBubble(msg);
        },
      ),
    );
  }

  Widget inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x16000000), blurRadius: 12, offset: Offset(0, -5))],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: IconButton(
                onPressed: sending ? null : pickAndSendFile,
                icon: const Icon(Icons.attach_file_rounded),
                color: maroon,
                tooltip: 'Lampiran',
              ),
            ),
            Expanded(
              child: TextField(
                controller: messageC,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  filled: true,
                  fillColor: const Color(0xFFF7F8FC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFF0D6DF))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: maroon)),
                ),
                onSubmitted: (_) => sendText(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: FilledButton(
                onPressed: sending ? null : () => sendText(),
                style: FilledButton.styleFrom(
                  backgroundColor: maroon,
                  disabledBackgroundColor: Colors.black12,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: sending
                    ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Chat CS'),
        backgroundColor: maroon,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => loadChat(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: maroon))
          : Column(children: [messageList(), inputBar()]),
    );
  }
}
