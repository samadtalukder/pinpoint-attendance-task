import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_capture/core/format.dart';

void main() {
  test('formatBytes picks a readable unit', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(999), '999 B');
    expect(formatBytes(1500), '1.5 KB');
    expect(formatBytes(1800000), '1.8 MB');
    expect(formatBytes(250000000), '250 MB');
    expect(formatBytes(3200000000), '3.2 GB');
  });
}
