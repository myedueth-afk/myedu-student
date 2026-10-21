import 'dart:io';

import 'package:eschool/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

class ScreenProtectorWrapper extends StatefulWidget {
  const ScreenProtectorWrapper({
    super.key,
    required this.child,
  });

  /// The screen content to protect.
  final Widget child;

  @override
  State<ScreenProtectorWrapper> createState() => _ScreenProtectorWrapperState();
}

class _ScreenProtectorWrapperState extends State<ScreenProtectorWrapper> {
  @override
  void initState() {
    super.initState();
    _enableProtection();
  }

  @override
  void dispose() {
    _disableProtection();
    super.dispose();
  }

  /// Activates screenshot and screen-recording prevention.
  Future<void> _enableProtection() async {
    if (!isScreenProtectionEnabled) return;

    try {
      if (Platform.isAndroid) {
        await ScreenProtector.protectDataLeakageOn();
      } else if (Platform.isIOS) {
        await ScreenProtector.preventScreenshotOn();
        await ScreenProtector.protectDataLeakageWithColor(
          Colors.white,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ScreenProtectorWrapper: enable failed — $e');
      }
    }
  }

  /// Deactivates screenshot and screen-recording prevention so that
  /// other screens in the app are not affected.
  Future<void> _disableProtection() async {
    if (!isScreenProtectionEnabled) return;

    try {
      if (Platform.isAndroid) {
        await ScreenProtector.protectDataLeakageOff();
      } else if (Platform.isIOS) {
        await ScreenProtector.preventScreenshotOff();
        await ScreenProtector.protectDataLeakageWithColorOff();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ScreenProtectorWrapper: disable failed — $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
