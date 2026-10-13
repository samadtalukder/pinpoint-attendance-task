import 'package:camera/camera.dart';

import '../../core/constants.dart';

/// Picks the ultrawide among the back cameras. The plugin often reports
/// `CameraLensType.unknown` (seen on Samsung), so a lens also counts when its
/// 35mm-equivalent focal length is well below the main camera's.
///
/// [equivalentMm] maps camera name to focal length; missing data means the
/// lens is never guessed.
CameraDescription? findUltraWide({
  required List<CameraDescription> back,
  required CameraDescription main,
  required Map<String, double> equivalentMm,
}) {
  final mainMm = equivalentMm[main.name];
  final candidates = back.where((c) => c != main).where((c) {
    if (c.lensType == CameraLensType.ultraWide) return true;
    final mm = equivalentMm[c.name];
    return mm != null &&
        mainMm != null &&
        mm <= mainMm * ZoomConstants.ultraWideFocalRatio;
  }).toList();
  if (candidates.isEmpty) return null;
  candidates.sort(
    (a, b) => (equivalentMm[a.name] ?? 0).compareTo(equivalentMm[b.name] ?? 0),
  );
  return candidates.first;
}
