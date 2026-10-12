import 'package:flutter/material.dart';

import '../../../core/strings.dart';

/// Icon plus text, so connection state is not conveyed by color alone.
class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key, required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = online ? scheme.primary : scheme.error;
    return Chip(
      avatar: Icon(
        online ? Icons.wifi : Icons.wifi_off,
        size: 18,
        color: color,
      ),
      label: Text(online ? AppStrings.online : AppStrings.offline),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
