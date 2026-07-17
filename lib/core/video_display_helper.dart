import 'image_url_helper.dart';

class VideoDisplayHelper {
  static String title(Map<String, dynamic> video) {
    return (video['title'] ??
            video['name'] ??
            video['caption'] ??
            'MI MART TV')
        .toString();
  }

  static String description(Map<String, dynamic> video) {
    return (video['description'] ??
            video['caption'] ??
            video['subtitle'] ??
            '')
        .toString();
  }

  static String videoUrl(Map<String, dynamic> video) {
    return (video['video_url'] ??
            video['youtube_url'] ??
            video['url'] ??
            video['link'] ??
            '')
        .toString()
        .trim();
  }

  static String thumbnail(Map<String, dynamic> video) {
    final direct = (video['thumbnail_url'] ??
            video['thumbnail'] ??
            video['image_url'] ??
            video['image_path'] ??
            video['cover_image'] ??
            video['poster'] ??
            '')
        .toString()
        .trim();

    if (direct.isNotEmpty && direct != 'null') {
      return ImageUrlHelper.normalize(direct);
    }

    final id = youtubeIdFromUrl(videoUrl(video));

    if (id.isNotEmpty) {
      return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }

    return '';
  }

  static String youtubeIdFromUrl(String url) {
    if (url.isEmpty) return '';

    final uri = Uri.tryParse(url);
    if (uri == null) return '';

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    }

    final queryId = uri.queryParameters['v'];
    if (queryId != null && queryId.isNotEmpty) return queryId;

    final segs = uri.pathSegments;

    final embedIndex = segs.indexOf('embed');
    if (embedIndex >= 0 && segs.length > embedIndex + 1) {
      return segs[embedIndex + 1];
    }

    final shortsIndex = segs.indexOf('shorts');
    if (shortsIndex >= 0 && segs.length > shortsIndex + 1) {
      return segs[shortsIndex + 1];
    }

    return '';
  }
}
