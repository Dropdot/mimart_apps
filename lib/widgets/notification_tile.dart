import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const NotificationTile({super.key, required this.data});

  String get title {
    return (data['title'] ??
            data['name'] ??
            data['message_text'] ??
            data['order_code'] ??
            '-')
        .toString();
  }

  String get subtitle {
    return (data['body'] ??
            data['description'] ??
            data['created_at'] ??
            data['order_status'] ??
            '')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
    );
  }
}
