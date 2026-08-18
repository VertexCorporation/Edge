import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase.dart';
import '../utils/browser_notify.dart';
import 'chat.dart';

class InboxNotice {
  final String title;
  final String body;
  final String? chatId;

  const InboxNotice({
    required this.title,
    required this.body,
    this.chatId,
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    await Firebase.initializeApp(options: options);
  } else {
    await Firebase.initializeApp();
  }
  debugPrint("Arkaplanda mesaj alındı: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _inbox = StreamController<InboxNotice>.broadcast();

  Stream<InboxNotice> get inboxNotices => _inbox.stream;

  bool _isInitialized = false;
  bool _tokenRefreshListenerAttached = false;
  bool _prefsLoaded = false;
  bool _enabled = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatAlertSub;
  DateTime? _alertsReadyAt;
  String? _alertUid;

  static const _enabledPrefsKey = 'inbox_notifications_enabled';

  bool get enabled => _enabled;

  Future<void> ensurePrefsLoaded() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledPrefsKey) ?? true;
    } catch (e) {
      debugPrint('Notification prefs load failed: $e');
    }
    _prefsLoaded = true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    _prefsLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledPrefsKey, value);
    } catch (e) {
      debugPrint('Notification prefs save failed: $e');
    }
    if (value) {
      startInboxAlerts();
    } else {
      stopInboxAlerts();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await ensurePrefsLoaded();

    if (kIsWeb) {
      await requestBrowserNotifications();
    } else {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Notification permission failed: $e');
    }

    if (!kIsWeb) {
      await _initNativeLocalNotifications();
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      presentInboxNotice(
        InboxNotice(
          title: notification.title ?? 'Yeni mesaj',
          body: notification.body ?? 'Sana bir mesaj gönderildi.',
        ),
      );
    });

    _isInitialized = true;
    await saveDeviceToken();
    startInboxAlerts();
  }

  Future<void> _initNativeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(settings: initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void presentInboxNotice(InboxNotice notice) {
    if (!_enabled) return;
    if (!_inbox.isClosed) {
      _inbox.add(notice);
    }
    showBrowserNotification(notice.title, notice.body);
    if (!kIsWeb) {
      _showNativeBanner(notice);
    }
  }

  Future<void> _showNativeBanner(InboxNotice notice) async {
    try {
      await _localNotifications.show(
        id: notice.hashCode,
        title: notice.title,
        body: notice.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            icon: '@mipmap/launcher_icon',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Local notification failed: $e');
    }
  }

  Future<void> saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (!await _fcm.isSupported()) return;
      final token = await _fcm.getToken();
      if (token != null) {
        await _persistToken(user.uid, token);
      }

      if (!_tokenRefreshListenerAttached) {
        _tokenRefreshListenerAttached = true;
        _fcm.onTokenRefresh.listen((newToken) async {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await _persistToken(currentUser.uid, newToken);
          }
        });
      }
    } catch (e) {
      debugPrint("FCM token alınamadı: $e");
    }
  }

  Future<void> _persistToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('FCM token users write failed: $e');
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('usernames')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('FCM token usernames write failed: $e');
    }
  }

  /// Site açıkken yeni mesajları banner + tarayıcı bildirimi olarak gösterir.
  void startInboxAlerts() {
    ensurePrefsLoaded().then((_) {
      if (!_enabled) {
        stopInboxAlerts();
        return;
      }
      _attachInboxAlerts();
    });
  }

  void _attachInboxAlerts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_alertUid == uid && _chatAlertSub != null) return;

    stopInboxAlerts();
    _alertUid = uid;
    _alertsReadyAt = DateTime.now();

    _chatAlertSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen((snap) {
      final readyAt = _alertsReadyAt;
      if (readyAt == null) return;
      final warmup = DateTime.now().difference(readyAt) <
          const Duration(seconds: 2);

      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.removed) continue;
        if (warmup && change.type == DocumentChangeType.added) continue;

        final data = change.doc.data();
        if (data == null || data['deleted'] == true) continue;

        final senderId = data['lastSenderId'] as String?;
        if (senderId == null || senderId == uid) continue;
        if (ChatService.activeChatId == change.doc.id) continue;

        final ts = data['lastMessageTimestamp'];
        if (ts is Timestamp && ts.toDate().isBefore(readyAt)) continue;

        final isGroup = data['isGroup'] == true;
        final title = isGroup
            ? ((data['groupName'] as String?)?.trim().isNotEmpty == true
                ? data['groupName'] as String
                : 'Grup')
            : 'Yeni mesaj';
        final type = data['lastMessageType'] as String? ?? 'text';
        presentInboxNotice(
          InboxNotice(
            title: title,
            body: type == 'text'
                ? 'Sana bir mesaj gönderildi.'
                : 'Sana bir dosya gönderildi.',
            chatId: change.doc.id,
          ),
        );
      }
    }, onError: (e) {
      debugPrint('Inbox alert listen failed: $e');
    });
  }

  void stopInboxAlerts() {
    _chatAlertSub?.cancel();
    _chatAlertSub = null;
    _alertUid = null;
    _alertsReadyAt = null;
  }
}
