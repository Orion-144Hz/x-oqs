import 'package:flutter/services.dart';

/// Stub for 10-band EQ (platform channel or equalizer_flutter).
class EqualizerBridge {
  static const _ch = MethodChannel('com.xoqs.x_oqs/equalizer');

  Future<void> setEnabled(bool enabled) async {
    try {
      await _ch.invokeMethod<void>('setEnabled', enabled);
    } on MissingPluginException {
      // No native implementation yet.
    }
  }

  Future<void> setBandGain(int bandIndex, double gainDb) async {
    try {
      await _ch.invokeMethod<void>('setBand', {'band': bandIndex, 'gain': gainDb});
    } on MissingPluginException {}
  }
}
