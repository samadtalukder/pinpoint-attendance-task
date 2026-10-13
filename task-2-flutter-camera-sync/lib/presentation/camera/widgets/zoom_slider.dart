import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import 'zoom_preset_buttons.dart';

/// Vertical zoom pill with the maximum on top and the minimum below, minimum
/// at the bottom of the track.
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

  static const double _length = 240;
  static const double _width = 44;

  @override
  Widget build(BuildContext context) {
    if (max <= min) return const SizedBox.shrink();
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(_width / 2),
      ),
      child: SizedBox(
        width: _width,
        height: _length,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(ZoomPresetButtons.labelFor(max), style: labelStyle),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white30,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                  ),
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
            ),
            Text(ZoomPresetButtons.labelFor(min), style: labelStyle),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
