import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/auth_gate.dart';
import '../core/formatters.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool loading = true;
  List<dynamic> videos = [];

  final Set<int> likedVideos = {};
  final Map<int, int> lastLikeClickAt = {};
  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    pageController.dispose();
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

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.get('videos.php');
      final data = dataOrRoot(res);
      if (!mounted) return;
      setState(() {
        videos = data['videos'] as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        videos = [];
        loading = false;
      });
    }
  }

  Map<String, dynamic> videoAt(int index) => Map<String, dynamic>.from(videos[index] as Map);

  String compact(num number) {
    final n = number.toInt();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    return '$n';
  }

  Future<void> likeVideo(Map<String, dynamic> video, {bool boost = false}) async {
    final id = int.tryParse('${video['id']}') ?? 0;
    if (id <= 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastClick = lastLikeClickAt[id] ?? 0;
    final clickGap = now - lastClick;
    lastLikeClickAt[id] = now;

    final isFastClick = boost || (lastClick > 0 && clickGap <= 450);
    final isCurrentlyLiked = likedVideos.contains(id);

    String action;
    int localDelta;

    if (isFastClick) {
      action = 'boost';
      localDelta = 1;
      likedVideos.add(id);
    } else if (isCurrentlyLiked) {
      action = 'unlike';
      localDelta = -1;
      likedVideos.remove(id);
    } else {
      action = 'like';
      localDelta = 1;
      likedVideos.add(id);
    }

    final oldLikes = int.tryParse('${video['likes_count'] ?? 0}') ?? 0;
    final localNext = (oldLikes + localDelta).clamp(0, 1 << 31);

    setState(() {
      video['likes_count'] = localNext;
      video['likes_text'] = compact(localNext);
    });

    try {
      final res = await ApiClient.post('video_like.php', body: {'id': id, 'action': action});
      final data = dataOrRoot(res);
      if (!mounted) return;
      if (ok(res) && data['likes'] != null) {
        final likes = int.tryParse('${data['likes']}') ?? localNext;
        setState(() {
          video['likes_count'] = likes;
          video['likes_text'] = data['likes_text'] ?? compact(likes);
        });
      }
    } catch (_) {}
  }

  Future<void> shareVideo(Map<String, dynamic> video) async {
    final id = int.tryParse('${video['id']}') ?? 0;
    final shareUrl = id > 0
        ? 'https://mimart.dropdot.my.id/tampilan_user/video.php?video=$id'
        : 'https://mimart.dropdot.my.id/tampilan_user/video.php';

    await Clipboard.setData(ClipboardData(text: shareUrl));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link video berhasil disalin.')),
    );
  }

  Widget mediaStage(Map<String, dynamic> video) {
    final thumb = (video['thumbnail_url'] ?? '').toString();

    if (thumb.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            thumb,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => mediaFallback(),
          ),
          Container(color: Colors.black.withOpacity(.25)),
          const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 76)),
        ],
      );
    }

    return mediaFallback();
  }

  Widget mediaFallback() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 76),
      ),
    );
  }

  Widget actionButton({required IconData icon, required String label, required VoidCallback onTap, Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 29),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget videoSlide(Map<String, dynamic> video) {
    final id = int.tryParse('${video['id']}') ?? 0;
    final title = (video['title'] ?? '').toString();
    final subtitle = (video['subtitle'] ?? '').toString();
    final likes = (video['likes_text'] ?? compact(int.tryParse('${video['likes_count'] ?? 0}') ?? 0)).toString();
    final comments = (video['comments_text'] ?? compact(int.tryParse('${video['comments_count'] ?? 0}') ?? 0)).toString();
    final isLiked = likedVideos.contains(id);

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
                  const Text('MI.TV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
            ),
            Expanded(
              flex: 7,
              child: GestureDetector(
                onDoubleTap: () => likeVideo(video, boost: true),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)),
                  clipBehavior: Clip.antiAlias,
                  child: mediaStage(video),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                color: const Color(0xFF111827),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(radius: 15, backgroundColor: Colors.white, child: Text('MI', style: TextStyle(color: Color(0xFF97002B), fontWeight: FontWeight.w900, fontSize: 10))),
                                SizedBox(width: 8),
                                Text('MI MART Official', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (title.isNotEmpty)
                              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, height: 1.25)),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(.78), fontSize: 12.5, height: 1.25)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        actionButton(icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: likes, color: isLiked ? const Color(0xFFEF4444) : Colors.white, onTap: () => likeVideo(video)),
                        actionButton(icon: Icons.mode_comment_outlined, label: comments, onTap: () => openComments(video)),
                        actionButton(icon: Icons.share_rounded, label: 'Share', onTap: () => shareVideo(video)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openComments(Map<String, dynamic> video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VideoCommentsSheet(
        video: video,
        onChanged: (total) {
          setState(() {
            video['comments_count'] = total;
            video['comments_text'] = compact(total);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));

    if (videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('MI.TV'), backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: const Center(child: Text('Belum ada konten video.', style: TextStyle(color: Colors.white70))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        itemBuilder: (_, index) => videoSlide(videoAt(index)),
      ),
    );
  }
}

class _VideoCommentsSheet extends StatefulWidget {
  final Map<String, dynamic> video;
  final ValueChanged<int> onChanged;

  const _VideoCommentsSheet({required this.video, required this.onChanged});

  @override
  State<_VideoCommentsSheet> createState() => _VideoCommentsSheetState();
}

class _VideoCommentsSheetState extends State<_VideoCommentsSheet> {
  bool loading = true;
  bool sending = false;
  List<dynamic> comments = [];
  int total = 0;
  final commentC = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadComments();
  }

  @override
  void dispose() {
    commentC.dispose();
    super.dispose();
  }

  Map<String, dynamic> dataOrRoot(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return res;
  }

  bool ok(Map<String, dynamic> res) => res['success'] == true || res['status'] == 'success' || res['ok'] == true;

  Future<void> loadComments() async {
    final id = widget.video['id'];
    setState(() => loading = true);
    try {
      final res = await ApiClient.get('video_comments_list.php', query: {'video_id': '$id'});
      final data = dataOrRoot(res);
      if (!mounted) return;
      setState(() {
        comments = data['comments'] as List<dynamic>? ?? [];
        total = int.tryParse('${data['total_comments'] ?? 0}') ?? 0;
        loading = false;
      });
      widget.onChanged(total);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        comments = [];
        total = 0;
        loading = false;
      });
    }
  }

  Future<void> sendComment() async {
    final isLogin = await AuthGate.isLoggedIn();
    if (!isLogin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login dulu untuk berkomentar.')));
      return;
    }

    final text = commentC.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Komentar tidak boleh kosong.')));
      return;
    }

    setState(() => sending = true);

    try {
      final res = await ApiClient.post('video_comment_add.php', body: {'video_id': widget.video['id'], 'comment_text': text});
      if (!mounted) return;
      if (ok(res)) {
        final data = dataOrRoot(res);
        commentC.clear();
        setState(() {
          total = int.tryParse('${data['total_comments'] ?? total + 1}') ?? total + 1;
          if (data['comment'] is Map) comments.insert(0, Map<String, dynamic>.from(data['comment'] as Map));
        });
        widget.onChanged(total);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((res['message'] ?? 'Gagal mengirim komentar.').toString())));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim komentar.')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> deleteComment(Map<String, dynamic> comment) async {
    final id = comment['id'];
    if (id == null) return;

    try {
      final res = await ApiClient.post('video_comment_delete.php', body: {'comment_id': id});
      if (!mounted) return;
      if (ok(res)) {
        final data = dataOrRoot(res);
        setState(() {
          comments.removeWhere((item) => '${(item as Map)['id']}' == '$id');
          total = int.tryParse('${data['total_comments'] ?? total - 1}') ?? total - 1;
          if (total < 0) total = 0;
        });
        widget.onChanged(total);
      }
    } catch (_) {}
  }

  Widget commentItem(Map<String, dynamic> comment) {
    final username = (comment['username'] ?? 'Pengguna MI MART').toString();
    final initial = username.trim().isEmpty ? 'M' : username.trim().substring(0, 1).toUpperCase();
    final text = (comment['comment_text'] ?? '').toString();
    final label = (comment['created_label'] ?? '').toString();
    final canDelete = comment['can_delete'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundColor: const Color(0xFFFFEEF2), child: Text(initial, style: const TextStyle(color: Color(0xFF97002B), fontWeight: FontWeight.w900))),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(username, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5))),
                  if (label.isNotEmpty) Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11)),
                ]),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(height: 1.35)),
                if (canDelete) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => deleteComment(comment), child: const Text('Hapus'))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .64,
      minChildSize: .40,
      maxChildSize: .94,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Row(children: [
                Expanded(child: Text('Komentar ($total)', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : comments.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada komentar. Jadilah yang pertama berkomentar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))))
                      : RefreshIndicator(
                          onRefresh: loadComments,
                          child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: comments.map((e) => commentItem(Map<String, dynamic>.from(e as Map))).toList()),
                        ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: commentC,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Tulis komentar...',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: sending ? null : sendComment,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF97002B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                    child: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Kirim'),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}
