import 'dart:html' as html;

Future<void> requestBrowserNotifications() async {
  if (!html.Notification.supported) return;
  try {
    await html.Notification.requestPermission();
  } catch (_) {}
}

void showBrowserNotification(String title, String body) {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;
  try {
    html.Notification(
      title,
      body: body,
      icon: 'icons/Icon-192.png',
    );
  } catch (_) {}
}

bool isBrowserTabHidden() {
  try {
    return html.document.hidden ?? false;
  } catch (_) {
    return false;
  }
}
