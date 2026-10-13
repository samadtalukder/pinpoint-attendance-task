import 'package:flutter/widgets.dart';

/// Gives the screen a live preview widget without knowing the camera plugin.
/// Widget tests supply a plain box.
abstract interface class CameraPreviewSource {
  /// Width over height of the preview in portrait, used to fill the screen
  /// without stretching.
  double get aspectRatio;

  Widget buildPreview();
}
