import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../domain/entities/captured_image.dart';

/// Thumbnail of the current batch, shutter button and a spacer so the
/// shutter stays centered.
class CaptureBar extends StatelessWidget {
  const CaptureBar({
    super.key,
    required this.batch,
    required this.canCapture,
    required this.onCapture,
  });

  final List<CapturedImage> batch;
  final bool canCapture;
  final VoidCallback onCapture;

  static const double _shutterSize = 76;
  static const double _thumbSize = 56;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BatchThumbnail(batch: batch),
        Semantics(
          button: true,
          enabled: canCapture,
          label: AppStrings.takePhoto,
          excludeSemantics: true,
          child: GestureDetector(
            key: const Key('shutter'),
            onTap: canCapture ? onCapture : null,
            child: AnimatedOpacity(
              opacity: canCapture ? 1 : 0.5,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: _shutterSize,
                height: _shutterSize,
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 4),
                  ),
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: _thumbSize),
      ],
    );
  }
}

class _BatchThumbnail extends StatelessWidget {
  const _BatchThumbnail({required this.batch});

  final List<CapturedImage> batch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = batch.isEmpty ? null : batch.last;
    const size = CaptureBar._thumbSize;
    return Semantics(
      label: batch.isEmpty
          ? AppStrings.batchEmptyLabel
          : AppStrings.batchPhotoCount(batch.length),
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: size,
                height: size,
                child: last == null
                    ? const ColoredBox(
                        color: Colors.white12,
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white70,
                        ),
                      )
                    : Image.file(
                        File(last.path),
                        fit: BoxFit.cover,
                        cacheWidth: 160,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Colors.white12,
                          child: Icon(Icons.image, color: Colors.white70),
                        ),
                      ),
              ),
            ),
            if (batch.isNotEmpty)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  key: const Key('batch_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${batch.length}',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
