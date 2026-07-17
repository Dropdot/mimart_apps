import 'dart:convert';

import 'app_config.dart';

class ImageUrlHelper {
  static String fromProduct(Map<String, dynamic> data) {
    final direct = _firstNotEmpty([
      data['image_url'],
      data['image_path'],
      _firstGallery(data['gallery_urls']),
      _firstGallery(data['gallery_images']),
    ]);

    return normalize(direct);
  }

  static String normalize(dynamic value) {
    var raw = (value ?? '').toString().trim();

    if (raw.isEmpty || raw == 'null') {
      return '${AppConfig.assetBaseUrl}/asset/banner.jpeg';
    }

    if (raw.startsWith('[')) {
      raw = _firstGallery(raw);
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return Uri.encodeFull(raw);
    }

    if (raw.startsWith('//')) {
      return Uri.encodeFull('https:$raw');
    }

    if (raw.startsWith('/')) {
      return Uri.encodeFull('${AppConfig.assetBaseUrl}$raw');
    }

    return Uri.encodeFull('${AppConfig.assetBaseUrl}/$raw');
  }

  static String _firstNotEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  static String _firstGallery(dynamic value) {
    if (value == null) return '';
    if (value is List && value.isNotEmpty) return (value.first ?? '').toString();

    final raw = value.toString().trim();
    if (raw.isEmpty) return '';

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List && decoded.isNotEmpty) return (decoded.first ?? '').toString();
    } catch (_) {
      return raw;
    }

    return '';
  }
}
