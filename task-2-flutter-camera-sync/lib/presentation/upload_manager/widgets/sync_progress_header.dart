import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/strings.dart';
import '../upload_queue_state.dart';

class SyncProgressHeader extends StatelessWidget {
  const SyncProgressHeader({
    super.key,
    required this.state,
    required this.onRetryNow,
  });

  final UploadQueueState state;
  final VoidCallback onRetryNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (state.progress * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.batchSyncProgress,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Text('$percent%', style: theme.textTheme.labelLarge),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.uploadedCount(state.syncedCount, state.total)}'
                  ' · ${AppStrings.sizeProgress(formatBytes(state.syncedBytes), formatBytes(state.totalBytes))}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: state.pendingCount > 0 && !state.isUploading
                    ? onRetryNow
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retryNow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
