import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PanelLinkSection extends StatelessWidget {
  final Uri? url;
  final VoidCallback onTap;

  const PanelLinkSection({
    required this.url,
    required this.onTap,
    super.key,
  });

  String extractDomainFromUri(Uri? uri) {
    RegExp domainRegex = RegExp(r'^(?:https?:\/\/)?(?:www\.)?([^\/]+)');
    String? domain;
    if (uri != null && domainRegex.hasMatch(uri.toString())) {
      domain = domainRegex.firstMatch(uri.toString())?.group(1);
    }
    return domain ?? 'Invalid URI';
  }

  @override
  Widget build(BuildContext context) {
    if (url == null) return const SizedBox.shrink();

    return ListTile(
      leading: const FaIcon(FontAwesomeIcons.link, size: 18),
      title: Text(
        extractDomainFromUri(url),
        style: const TextStyle(fontSize: 14),
      ),
      visualDensity: const VisualDensity(vertical: -4),
      onTap: onTap,
    );
  }
}