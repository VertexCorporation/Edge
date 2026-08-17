import 'dart:html' as html;
import 'package:flutter/foundation.dart';

bool isIosDevice() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  if (ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod')) {
    return true;
  }
  // iPadOS 13+ often reports as Macintosh with a touch screen.
  final maxTouch = html.window.navigator.maxTouchPoints ?? 0;
  if (ua.contains('macintosh') && maxTouch > 1) {
    return true;
  }
  return defaultTargetPlatform == TargetPlatform.iOS;
}
