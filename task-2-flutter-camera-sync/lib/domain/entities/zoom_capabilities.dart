import 'package:equatable/equatable.dart';

import '../../core/constants.dart';

/// Zoom range of the active back camera. A [min] of 0.5 or less means the
/// device has an ultrawide lens.
class ZoomCapabilities extends Equatable {
  const ZoomCapabilities({required this.min, required this.max});

  final double min;
  final double max;

  bool get hasUltraWide => min <= ZoomConstants.ultraWide;

  /// Buttons to show: 0.5x only with an ultrawide lens, 2x only when
  /// reachable.
  List<double> get presets => [
    if (hasUltraWide) ZoomConstants.ultraWide,
    ZoomConstants.main,
    if (max >= ZoomConstants.telephoto) ZoomConstants.telephoto,
  ];

  double clamp(double zoom) => zoom.clamp(min, max);

  @override
  List<Object?> get props => [min, max];
}
