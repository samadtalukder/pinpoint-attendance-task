import 'package:flutter/widgets.dart';

/// Gives the screen a live preview widget without knowing the camera plugin.
/// Widget tests supply a plain box.
abstract interface class CameraPreviewSource {
  Widget buildPreview();
}
