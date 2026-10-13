import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/strings.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/pending_upload.dart';
import '../../../domain/entities/upload_status.dart';

class UploadTile extends StatelessWidget {
  const UploadTile({
    super.key,
    required this.upload,
    required this.online,
    required this.paused,
  });

  final PendingUpload upload;
  final bool online;

  /// The user paused syncing; waiting and retrying rows say so.
  final bool paused;

  static const double _thumbSize = 56;
  static const double _syncedOpacity = 0.6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<StatusColors>()!;
    final synced = upload.status == UploadStatus.synced;
    final holding =
        paused && !synced && upload.status != UploadStatus.uploading;
    final (icon, label, color) = holding
        ? (Icons.pause_circle_outline, AppStrings.statusPaused, colors.queued)
        : switch (upload.status) {
            UploadStatus.waiting when !online => (
              Icons.cloud_off,
              AppStrings.statusWaitingOffline,
              colors.waiting,
            ),
            UploadStatus.waiting => (
              Icons.schedule,
              AppStrings.statusWaiting,
              colors.queued,
            ),
            UploadStatus.uploading => (
              Icons.cloud_upload_outlined,
              AppStrings.statusUploading,
              colors.uploading,
            ),
            UploadStatus.retrying => (
              Icons.sync_problem,
              AppStrings.statusRetrying(upload.attempts),
              colors.retrying,
            ),
            UploadStatus.synced => (
              Icons.check_circle_outline,
              AppStrings.statusSynced,
              colors.synced,
            ),
          };

    return Opacity(
      opacity: synced ? _syncedOpacity : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: _thumbSize,
                  height: _thumbSize,
                  child: Image.file(
                    File(upload.filePath),
                    fit: BoxFit.cover,
                    cacheWidth: 160,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upload.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      formatBytes(upload.sizeBytes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label.toUpperCase(),
                            style: AppTheme.label(context, color: color),
                          ),
                        ),
                      ],
                    ),
                    if (upload.status == UploadStatus.uploading && !holding)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: const LinearProgressIndicator(minHeight: 4),
                        ),
                      ),
                    if (upload.status == UploadStatus.retrying &&
                        upload.lastError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          upload.lastError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
