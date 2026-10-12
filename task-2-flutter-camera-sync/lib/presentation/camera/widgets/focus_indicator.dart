import 'package:flutter/material.dart';

/// Ring drawn where the user tapped to focus. It settles in, holds, then
/// fades. A new [id] replays it.
class FocusIndicator extends StatelessWidget {
  const FocusIndicator({super.key, required this.center, required this.id});

  /// Position inside the preview, in logical pixels.
  final Offset center;
  final int id;

  static const double size = 72;
  static const Duration duration = Duration(milliseconds: 1500);
  static const double _settleEnd = 0.25;
  static const double _holdEnd = 0.7;
  static const double _startScale = 1.5;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(id),
            tween: Tween(begin: 0, end: 1),
            duration: duration,
            builder: (context, t, _) {
              final settle = Curves.easeOut.transform(
                (t / _settleEnd).clamp(0, 1),
              );
              final fade = t <= _holdEnd
                  ? 1.0
                  : 1 - (t - _holdEnd) / (1 - _holdEnd);
              return Opacity(
                opacity: fade.clamp(0, 1),
                child: Transform.scale(
                  scale: _startScale - (_startScale - 1) * settle,
                  child: const DecoratedBox(
                    key: Key('focus_indicator'),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.amber, width: 2),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
