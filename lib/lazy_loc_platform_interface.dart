import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'lazy_loc_method_channel.dart';

abstract class LazyLocPlatform extends PlatformInterface {
  /// Constructs a LazyLocPlatform.
  LazyLocPlatform() : super(token: _token);

  static final Object _token = Object();

  static LazyLocPlatform _instance = MethodChannelLazyLoc();

  /// The default instance of [LazyLocPlatform] to use.
  ///
  /// Defaults to [MethodChannelLazyLoc].
  static LazyLocPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LazyLocPlatform] when
  /// they register themselves.
  static set instance(LazyLocPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
