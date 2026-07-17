import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../core/video_display_helper.dart';

class VideoPlayerSheet {
  static Future<void> open(
    BuildContext context,
    Map<String, dynamic> video,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VideoPlayerSheetContent(video: video),
    );
  }
}

class _VideoPlayerSheetContent extends StatefulWidget {
  final Map<String, dynamic> video;

  const _VideoPlayerSheetContent({
    required this.video,
  });

  @override
  State<_VideoPlayerSheetContent> createState() => _VideoPlayerSheetContentState();
}

class _VideoPlayerSheetContentState extends State<_VideoPlayerSheetContent> {
  YoutubePlayerController? controller;
  late final String title;
  late final String description;
  late final String url;
  late final String youtubeId;

  @override
  void initState() {
    super.initState();

    title = VideoDisplayHelper.title(widget.video);
    description = VideoDisplayHelper.description(widget.video);
    url = VideoDisplayHelper.videoUrl(widget.video);
    youtubeId = VideoDisplayHelper.youtubeIdFromUrl(url);

    if (youtubeId.isNotEmpty) {
      controller = YoutubePlayerController.fromVideoId(
        videoId: youtubeId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          showControls: true,
          mute: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    controller?.close();
    super.dispose();
  }

  Future<void> openExternal() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: controller == null
                    ? _FallbackVideoBox(onOpen: openExternal)
                    : YoutubePlayer(controller: controller!),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.16,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (url.isNotEmpty)
              OutlinedButton.icon(
                onPressed: openExternal,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Buka Video'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FallbackVideoBox extends StatelessWidget {
  final VoidCallback onOpen;

  const _FallbackVideoBox({
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1D2433),
      child: Center(
        child: FilledButton.icon(
          onPressed: onOpen,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF97002B),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Putar Video'),
        ),
      ),
    );
  }
}
