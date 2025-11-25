import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lazy_loc_platform_interface.dart';

/// An implementation of [LazyLocPlatform] that uses method channels.
class MethodChannelLazyLoc extends LazyLocPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lazy_loc');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
