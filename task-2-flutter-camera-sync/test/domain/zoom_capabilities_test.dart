import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_capture/domain/entities/zoom_capabilities.dart';

void main() {
  test('shows 0.5x only when the device reaches 0.5 or lower', () {
    expect(const ZoomCapabilities(min: 0.5, max: 8).presets, [0.5, 1.0, 2.0]);
    expect(const ZoomCapabilities(min: 0.6, max: 8).presets, [1.0, 2.0]);
    expect(const ZoomCapabilities(min: 1, max: 8).presets, [1.0, 2.0]);
  });

  test('hides 2x when max zoom is below 2', () {
    expect(const ZoomCapabilities(min: 1, max: 1.5).presets, [1.0]);
  });

  test('clamp keeps zoom inside the range', () {
    const caps = ZoomCapabilities(min: 0.5, max: 4);
    expect(caps.clamp(0.1), 0.5);
    expect(caps.clamp(2), 2);
    expect(caps.clamp(10), 4);
  });
}
