import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_capture/data/services/ultrawide_detection.dart';

CameraDescription cam(
  String name, {
  CameraLensType type = CameraLensType.unknown,
}) => CameraDescription(
  name: name,
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
  lensType: type,
);

void main() {
  final main = cam('0');

  test('plugin-reported ultrawide wins without focal data', () {
    final ultra = cam('2', type: CameraLensType.ultraWide);

    expect(
      findUltraWide(back: [main, ultra], main: main, equivalentMm: {}),
      ultra,
    );
  });

  test('unknown lens type is classified by focal length', () {
    final other = cam('2');

    final found = findUltraWide(
      back: [main, other],
      main: main,
      equivalentMm: {'0': 26, '2': 13},
    );

    expect(found, other);
  });

  test('telephoto and macro-like lenses are not ultrawide', () {
    final tele = cam('2');
    final macro = cam('3');

    final found = findUltraWide(
      back: [main, tele, macro],
      main: main,
      equivalentMm: {'0': 26, '2': 70, '3': 25},
    );

    expect(found, isNull);
  });

  test('picks the widest when several qualify', () {
    final a = cam('2');
    final b = cam('4');

    final found = findUltraWide(
      back: [main, a, b],
      main: main,
      equivalentMm: {'0': 26, '2': 16, '4': 12},
    );

    expect(found, b);
  });

  test('no focal data means no guess', () {
    final other = cam('2');

    expect(
      findUltraWide(back: [main, other], main: main, equivalentMm: {}),
      isNull,
    );
  });

  test('the main camera is never its own ultrawide', () {
    expect(
      findUltraWide(back: [main], main: main, equivalentMm: {'0': 26}),
      isNull,
    );
  });
}
