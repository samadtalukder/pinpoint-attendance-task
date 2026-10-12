import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/strings.dart';

/// Rounded 0.5x / 1x / 2x buttons. Only presets the device supports are
/// passed in, so a missing ultrawide lens shows no 0.5x button.
class ZoomPresetButtons extends StatelessWidget {
  const ZoomPresetButtons({
    super.key,
    required this.presets,
    required this.zoom,
    required this.onSelected,
  });

  final List<double> presets;
  final double zoom;
  final ValueChanged<double> onSelected;

  static const double _buttonSize = 48;

  static String labelFor(double preset) =>
      '${preset == preset.roundToDouble() ? preset.toInt() : preset}x';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final preset in presets)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _PresetButton(
              label: labelFor(preset),
              active: (zoom - preset).abs() < ZoomConstants.activeTolerance,
              onPressed: () => onSelected(preset),
            ),
          ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: active,
      label: AppStrings.zoomPreset(label),
      excludeSemantics: true,
      child: Material(
        color: active ? scheme.primary : Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: ZoomPresetButtons._buttonSize,
            height: ZoomPresetButtons._buttonSize,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? scheme.onPrimary : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
