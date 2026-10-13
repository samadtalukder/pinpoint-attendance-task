import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme.dart';

/// Dot plus text, so connection state is not conveyed by color alone.
class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key, required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StatusColors>()!;
    final color = online ? colors.synced : colors.retrying;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 6),
            Text(
              (online ? AppStrings.online : AppStrings.offline).toUpperCase(),
              style: AppTheme.label(context, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
