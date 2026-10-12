import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/strings.dart';
import '../../../domain/entities/pending_upload.dart';
import '../../../domain/entities/upload_status.dart';

class UploadTile extends StatelessWidget {
  const UploadTile({super.key, required this.upload, required this.online});

  final PendingUpload upload;
  final bool online;

  static const double _thumbSize = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, label, color) = switch (upload.status) {
      UploadStatus.waiting => (
        online ? Icons.schedule : Icons.cloud_off,
        online ? AppStrings.statusWaiting : AppStrings.statusWaitingOffline,
        scheme.onSurfaceVariant,
      ),
      UploadStatus.uploading => (
        Icons.cloud_upload_outlined,
        AppStrings.statusUploading,
        scheme.primary,
      ),
      UploadStatus.retrying => (
        Icons.sync_problem,
        AppStrings.statusRetrying(upload.attempts),
        scheme.error,
      ),
      UploadStatus.synced => (
        Icons.check_circle_outline,
        AppStrings.statusSynced,
        scheme.tertiary,
      ),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (upload.status == UploadStatus.retrying &&
                      upload.lastError != null)
                    Text(upload.lastError!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (upload.status == UploadStatus.uploading)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
