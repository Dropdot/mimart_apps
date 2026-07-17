// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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
  bool commentLoading = false;
  bool commentSending = false;

  List<dynamic> videos = [];
  List<dynamic> activeComments = [];

  int? activeCommentVideoId;
  int activeCommentTotal = 0;

  final Set<int> likedVideos = {};
  final Map<int, int> likesById = {};
  final Map<int, String> likesTextById = {};
  final Map<int, int> commentsById = {};
  final Map<int, String> commentsTextById = {};
  final Map<int, int> lastLikeClickAt = {};
  final Set<String> registeredViews = {};

  final PageController pageController = PageController();
  final TextEditingController commentC = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLikedMapFromLocalStorage();
    load();
  }

  @override
  void dispose() {
    pageController.dispose();
    commentC.dispose();
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

  void loadLikedMapFromLocalStorage() {
    likedVideos.clear();

    try {
      final raw = html.window.localStorage['mimart_video_liked_map'] ?? '{}';
      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (value == true) {
            final id = int.tryParse('$key') ?? 0;
            if (id > 0) likedVideos.add(id);
          }
        });
      }
    } catch (_) {}
  }

  void saveLikedMapToLocalStorage() {
    final map = <String, bool>{};

    for (final id in likedVideos) {
      map['$id'] = true;
    }

    try {
      html.window.localStorage['mimart_video_liked_map'] = jsonEncode(map);
    } catch (_) {}
  }

  String compact(num number) {
    final n = number.toInt();

    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    }

    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }

    return '$n';
  }

  void initCountersFromVideos() {
    likesById.clear();
    likesTextById.clear();
    commentsById.clear();
    commentsTextById.clear();

    for (final raw in videos) {
      if (raw is! Map) continue;

      final id = int.tryParse('${raw['id']}') ?? 0;
      if (id <= 0) continue;

      final likes = int.tryParse('${raw['likes_count'] ?? 0}') ?? 0;
      final comments = int.tryParse('${raw['comments_count'] ?? 0}') ?? 0;

      likesById[id] = likes;
      likesTextById[id] = (raw['likes_text'] ?? compact(likes)).toString();
      commentsById[id] = comments;
      commentsTextById[id] = (raw['comments_text'] ?? compact(comments)).toString();
    }
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final res = await ApiClient.get('videos.php');
      final data = dataOrRoot(res);

      if (!mounted) return;

      setState(() {
        videos = data['videos'] as List<dynamic>? ?? [];
        initCountersFromVideos();
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

  Map<String, dynamic> videoAt(int index) {
    return Map<String, dynamic>.from(videos[index] as Map);
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

    saveLikedMapToLocalStorage();

    final oldLikes = likesById[id] ?? int.tryParse('${video['likes_count'] ?? 0}') ?? 0;
    final localNext = (oldLikes + localDelta).clamp(0, 1 << 31);

    setState(() {
      likesById[id] = localNext;
      likesTextById[id] = compact(localNext);
    });

    try {
      final res = await ApiClient.post(
        'video_like.php',
        body: {
          'id': id,
          'action': action,
        },
      );

      final data = dataOrRoot(res);

      if (!mounted) return;

      if (ok(res) && data['likes'] != null) {
        final likes = int.tryParse('${data['likes']}') ?? localNext;

        setState(() {
          likesById[id] = likes;
          likesTextById[id] = data['likes_text']?.toString() ?? compact(likes);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((res['message'] ?? 'Gagal memproses like.').toString())),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memproses like.')),
      );
    }
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

  Future<void> openComments(Map<String, dynamic> video) async {
    final id = int.tryParse('${video['id']}') ?? 0;
    if (id <= 0) return;

    setState(() {
      activeCommentVideoId = id;
      activeComments = [];
      activeCommentTotal = commentsById[id] ?? int.tryParse('${video['comments_count'] ?? 0}') ?? 0;
      commentLoading = true;
      commentC.clear();
    });

    await loadComments(video);
  }

  void closeComments() {
    setState(() {
      activeCommentVideoId = null;
      activeComments = [];
      activeCommentTotal = 0;
      commentLoading = false;
      commentSending = false;
      commentC.clear();
    });
  }

  Future<void> loadComments(Map<String, dynamic> video) async {
    final id = int.tryParse('${video['id']}') ?? 0;
    if (id <= 0) return;

    setState(() => commentLoading = true);

    try {
      final res = await ApiClient.get(
        'video_comments_list.php',
        query: {'video_id': '$id'},
      );

      final data = dataOrRoot(res);

      if (!mounted) return;

      final total = int.tryParse('${data['total_comments'] ?? 0}') ?? 0;

      setState(() {
        activeCommentVideoId = id;
        activeComments = data['comments'] as List<dynamic>? ?? [];
        activeCommentTotal = total;
        commentsById[id] = total;
        commentsTextById[id] = compact(total);
        commentLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        activeComments = [];
        activeCommentTotal = 0;
        commentLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat komentar.')),
      );
    }
  }

  Future<void> sendComment(Map<String, dynamic> video) async {
    final isLogin = await AuthGate.isLoggedIn();

    if (!isLogin) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login dulu untuk berkomentar.')),
      );
      return;
    }

    final id = int.tryParse('${video['id']}') ?? 0;
    final text = commentC.text.trim();

    if (id <= 0) return;

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar tidak boleh kosong.')),
      );
      return;
    }

    setState(() => commentSending = true);

    try {
      final res = await ApiClient.post(
        'video_comment_add.php',
        body: {
          'video_id': id,
          'comment_text': text,
        },
      );

      if (!mounted) return;

      if (ok(res)) {
        final data = dataOrRoot(res);
        final total = int.tryParse('${data['total_comments'] ?? activeCommentTotal + 1}') ?? activeCommentTotal + 1;

        setState(() {
          commentC.clear();
          activeCommentTotal = total;
          commentsById[id] = total;
          commentsTextById[id] = compact(total);

          if (data['comment'] is Map) {
            activeComments.insert(0, Map<String, dynamic>.from(data['comment'] as Map));
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((res['message'] ?? 'Gagal mengirim komentar.').toString())),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim komentar.')),
      );
    } finally {
      if (mounted) setState(() => commentSending = false);
    }
  }

  Future<void> deleteComment(Map<String, dynamic> video, Map<String, dynamic> comment) async {
    final commentId = comment['id'];
    final videoId = int.tryParse('${video['id']}') ?? 0;

    if (commentId == null || videoId <= 0) return;

    try {
      final res = await ApiClient.post(
        'video_comment_delete.php',
        body: {'comment_id': commentId},
      );

      if (!mounted) return;

      if (ok(res)) {
        final data = dataOrRoot(res);
        final total = int.tryParse('${data['total_comments'] ?? activeCommentTotal - 1}') ?? activeCommentTotal - 1;

        setState(() {
          activeComments.removeWhere((item) => '${(item as Map)['id']}' == '$commentId');
          activeCommentTotal = total < 0 ? 0 : total;
          commentsById[videoId] = activeCommentTotal;
          commentsTextById[videoId] = compact(activeCommentTotal);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((res['message'] ?? 'Gagal menghapus komentar.').toString())),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus komentar.')),
      );
    }
  }

  String viewTypeFor(Map<String, dynamic> video) {
    final id = (video['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    final type = (video['media_type'] ?? 'media').toString();
    return 'mimart-tv-player-$type-$id';
  }

  Widget mediaView(Map<String, dynamic> video) {
    final viewType = viewTypeFor(video);
    final type = (video['media_type'] ?? 'external').toString();
    final url = (video['url'] ?? '').toString();
    final embed = (video['embed_url'] ?? '').toString();
    final thumb = (video['thumbnail_url'] ?? '').toString();

    if (!registeredViews.contains(viewType)) {
      registeredViews.add(viewType);

      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        if ((type == 'youtube' || type == 'instagram' || type == 'tiktok') && embed.isNotEmpty) {
          final iframe = html.IFrameElement()
            ..src = embed
            ..style.border = '0'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = 'black'
            ..style.pointerEvents = 'none'
            ..allow = 'autoplay; encrypted-media; picture-in-picture'
            ..allowFullscreen = true;

          return iframe;
        }

        if (type == 'video' && url.isNotEmpty) {
          final videoEl = html.VideoElement()
            ..src = url
            ..autoplay = true
            ..loop = true
            ..controls = true
            ..muted = false
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..style.backgroundColor = 'black'
            ..style.pointerEvents = 'none';

          videoEl.setAttribute('playsinline', 'true');
          videoEl.setAttribute('webkit-playsinline', 'true');

          return videoEl;
        }

        if (type == 'image' && url.isNotEmpty) {
          return html.ImageElement()
            ..src = url
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..style.backgroundColor = 'black'
            ..style.pointerEvents = 'none';
        }

        if (thumb.isNotEmpty) {
          return html.ImageElement()
            ..src = thumb
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..style.backgroundColor = 'black'
            ..style.pointerEvents = 'none';
        }

        return html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..style.backgroundColor = 'black'
          ..style.color = 'white'
          ..style.pointerEvents = 'none'
          ..innerText = 'Media tidak tersedia';
      });
    }

    return SizedBox.expand(
      child: IgnorePointer(
        ignoring: true,
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }

  Widget thumbnailBackdrop(Map<String, dynamic> video) {
    final thumb = (video['thumbnail_url'] ?? '').toString();

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumb.isNotEmpty)
            Image.network(
              thumb,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            )
          else
            Container(color: Colors.black),
          Container(color: Colors.black.withOpacity(.64)),
        ],
      ),
    );
  }

  Widget officialRow() {
    return const Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white,
          child: Text('MI', style: TextStyle(color: Color(0xFF97002B), fontWeight: FontWeight.w900, fontSize: 10)),
        ),
        SizedBox(width: 8),
        Text('MI MART Official', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget sideAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return SizedBox(
      width: 68,
      height: 76,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFFEF4444) : Colors.white,
              size: 32,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget productCard(Map<String, dynamic> video) {
    final product = Map<String, dynamic>.from(video['product'] as Map? ?? {});
    final hasProduct = product['has_product'] == true;

    if (!hasProduct) return const SizedBox.shrink();

    final name = (product['name'] ?? '').toString();
    final price = product['price'] ?? 0;

    return Container(
      width: 318,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.96),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.22), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF97002B)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w900, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(Formatters.rupiah(price), style: const TextStyle(color: Color(0xFF97002B), fontWeight: FontWeight.w900, fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF08A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFACC15)),
            ),
            child: const Text('Beli', style: TextStyle(color: Color(0xFFA16207), fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget bottomDetails(Map<String, dynamic> video) {
    final title = (video['title'] ?? '').toString();
    final subtitle = (video['subtitle'] ?? '').toString();

    return Positioned(
      left: 16,
      right: 82,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          officialRow(),
          const SizedBox(height: 10),
          if (title.isNotEmpty)
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14.5,
                height: 1.25,
                shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
              ),
            ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.84),
                fontSize: 12.5,
                height: 1.25,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
              ),
            ),
          ],
          productCard(video),
        ],
      ),
    );
  }

  Widget actionRail(Map<String, dynamic> video) {
    final id = int.tryParse('${video['id']}') ?? 0;
    final likes = likesTextById[id] ?? (video['likes_text'] ?? compact(int.tryParse('${video['likes_count'] ?? 0}') ?? 0)).toString();
    final comments = commentsTextById[id] ?? (video['comments_text'] ?? compact(int.tryParse('${video['comments_count'] ?? 0}') ?? 0)).toString();
    final isLiked = likedVideos.contains(id);

    return Positioned(
      right: 6,
      bottom: 170,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            sideAction(
              icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: likes,
              selected: isLiked,
              onTap: () => likeVideo(video),
            ),
            const SizedBox(height: 6),
            sideAction(
              icon: Icons.mode_comment_outlined,
              label: comments,
              onTap: () => openComments(video),
            ),
            const SizedBox(height: 6),
            sideAction(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: () => shareVideo(video),
            ),
          ],
        ),
      ),
    );
  }

  Widget commentItem(Map<String, dynamic> video, Map<String, dynamic> comment) {
    final username = (comment['username'] ?? 'Pengguna MI MART').toString();
    final initial = username.trim().isEmpty ? 'M' : username.trim().substring(0, 1).toUpperCase();
    final text = (comment['comment_text'] ?? '').toString();
    final label = (comment['created_label'] ?? '').toString();
    final canDelete = comment['can_delete'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFE5E7EB),
            child: Text(initial, style: const TextStyle(color: Color(0xFF97002B), fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(username, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 12.5)),
                    ),
                    if (label.isNotEmpty)
                      Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Color(0xFF334155), height: 1.30, fontSize: 12.5)),
                if (canDelete)
                  TextButton(
                    onPressed: () => deleteComment(video, comment),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Hapus', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget commentPage(Map<String, dynamic> video) {
    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 58,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: closeComments,
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Komentar MI.TV',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 190,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumbnailBackdrop(video),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            (video['title'] ?? 'MI MART TV').toString(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Komentar ($activeCommentTotal)',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                                ),
                              ),
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: IconButton(
                                  onPressed: closeComments,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: commentLoading
                            ? const Center(child: CircularProgressIndicator())
                            : activeComments.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(18),
                                      child: Text(
                                        'Belum ada komentar. Jadilah yang pertama berkomentar.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.black54, fontSize: 12.5),
                                      ),
                                    ),
                                  )
                                : ListView(
                                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                                    children: activeComments
                                        .map((e) => commentItem(video, Map<String, dynamic>.from(e as Map)))
                                        .toList(),
                                  ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentC,
                                maxLength: 500,
                                minLines: 1,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'Tulis komentar...',
                                  filled: true,
                                  fillColor: const Color(0xFFF7F8FC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 78,
                              height: 44,
                              child: FilledButton(
                                onPressed: commentSending ? null : () => sendComment(video),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF97002B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                ),
                                child: commentSending
                                    ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Kirim'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget videoSlide(Map<String, dynamic> video) {
    final id = int.tryParse('${video['id']}') ?? 0;

    if (activeCommentVideoId == id) {
      return commentPage(video);
    }

    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => likeVideo(video, boost: true),
                child: mediaView(video),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(.22),
                        Colors.transparent,
                        Colors.black.withOpacity(.82),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [.0, .48, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 58,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                      ),
                      const Text(
                        'MI.TV',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomDetails(video),
            actionRail(video),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('MI.TV'), backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: const Center(
          child: Text('Belum ada konten video.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              onPageChanged: (_) {
                closeComments();
              },
              itemBuilder: (_, index) => videoSlide(videoAt(index)),
            ),
          );
        },
      ),
    );
  }
}
