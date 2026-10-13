import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/strings.dart';
import '../../../core/theme.dart';
import '../upload_queue_state.dart';

class SyncProgressHeader extends StatelessWidget {
  const SyncProgressHeader({
    super.key,
    required this.state,
    required this.onPause,
    required this.onResume,
  });

  final UploadQueueState state;
  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (state.progress * 100).round();
    final canToggle = state.isPaused || state.pendingCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.batchSyncProgress.toUpperCase(),
                  style: AppTheme.label(
                    context,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text('$percent%', style: AppTheme.label(context)),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: AppStrings.progressSemantics(percent),
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.sizeProgress(
                    formatBytes(state.syncedBytes),
                    formatBytes(state.totalBytes),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (canToggle)
                TextButton.icon(
                  onPressed: state.isPaused ? onResume : onPause,
                  icon: Icon(
                    state.isPaused ? Icons.play_arrow : Icons.pause,
                    size: 18,
                  ),
                  label: Text(
                    (state.isPaused
                            ? AppStrings.resumeAll
                            : AppStrings.pauseAll)
                        .toUpperCase(),
                    style: AppTheme.label(context),
                  ),
                )
              else
                // Keeps the row height stable when nothing is left to pause.
                const SizedBox(height: kMinInteractiveDimension),
            ],
          ),
        ],
      ),
    );
  }
}
