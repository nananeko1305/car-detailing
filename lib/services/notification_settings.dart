import 'package:flutter/services.dart';

/// Opens the phone's notification settings for this app, where each kind of
/// push has its own switch (the channels in `MainActivity.kt`).
Future<void> openNotificationSettings() async {
  try {
    await const MethodChannel('car_detailing/settings')
        .invokeMethod<void>('openNotificationSettings');
  } catch (_) {
    // An old phone without the screen: nothing to open.
  }
}
