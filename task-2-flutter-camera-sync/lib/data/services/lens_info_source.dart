import 'package:flutter/services.dart';

import '../../core/constants.dart';

/// 35mm-equivalent focal length per camera id, from the platform camera
/// characteristics, which the `camera` plugin does not expose.
abstract interface class LensInfoSource {
  Future<Map<String, double>> equivalentFocalLengths();
}

class MethodChannelLensInfoSource implements LensInfoSource {
  static const MethodChannel _channel = MethodChannel(
    LensInfoConstants.channelName,
  );

  @override
  Future<Map<String, double>> equivalentFocalLengths() async {
    try {
      final raw = await _channel.invokeMapMethod<String, double>(
        LensInfoConstants.method,
      );
      return raw ?? const {};
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      // Platforms without the native side keep the plugin's own lens types.
      return const {};
    }
  }
}
