import 'package:flutter/material.dart';

import '../../../core/strings.dart';

/// Vertical zoom slider, minimum at the bottom.
class ZoomSlider extends StatelessWidget {
  const ZoomSlider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;

  static const double _length = 220;
  static const double _width = 48;

  @override
  Widget build(BuildContext context) {
    if (max <= min) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(_width / 2),
      ),
      child: SizedBox(
        width: _width,
        height: _length,
        child: RotatedBox(
          quarterTurns: 3,
          child: Slider(
            min: min,
            max: max,
            value: value.clamp(min, max),
            onChanged: onChanged,
            semanticFormatterCallback: (v) =>
                AppStrings.zoomValue(v.toStringAsFixed(1)),
          ),
        ),
      ),
    );
  }
}
