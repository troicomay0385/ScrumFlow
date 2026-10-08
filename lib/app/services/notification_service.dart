import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Xử lý thông báo khi app chạy ngầm (background) hoặc đã tắt (terminated)
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize(String userId) async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Xin quyền nhận thông báo
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      _isInitialized = false;
      return;
    }

    // 2. Lấy FCM Token và lưu lên Firestore
    try {
      final String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token, userId);
      }
      // Lắng nghe khi token thay đổi
      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken, userId);
      });
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // 3. Cấu hình flutter_local_notifications v22.x
    //    Chú ý: initialize() nhận named parameter `settings` (không phải positional)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings, // named param 'settings' (v22+)
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
        _handleNotificationClick(response.payload);
      },
    );

    // Bật hiển thị thông báo Foreground trên iOS
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Lắng nghe thông báo khi đang mở app (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Khi bấm vào thông báo từ background → mở app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNotificationClick(message.data['targetId'] as String?);
    });
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _saveTokenToFirestore(String token, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
      debugPrint('FCM Token saved for user $userId');
    } catch (e) {
      debugPrint('Error saving FCM Token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scrumflow_channel',       // channel id
      'ScrumFlow Notifications', // channel name
      channelDescription: 'Thông báo dự án và công việc từ ScrumFlow',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // show() nhận tất cả named params (v22+)
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: notificationDetails,
      payload: message.data['targetId'] as String?,
    );
  }

  void _handleNotificationClick(String? targetId) {
    if (targetId == null) return;
    // TODO: Điều hướng tới Task Detail / Story Detail qua GlobalKey<NavigatorState>.
    debugPrint('Should navigate to targetId: $targetId');
  }

  /// Hiển thị thông báo nhắc nhở hạn chót của Task trên thiết bị (US-059).
  Future<void> showTaskDeadlineAlert({
    required String taskTitle,
    required DateTime deadline,
    int? hoursRemaining,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scrumflow_deadline_channel',
      'Nhắc nhở Deadline Task',
      channelDescription: 'Thông báo nhắc nhở khi Task sắp đến hạn chót (US-059)',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    final String timeInfo = hoursRemaining != null && hoursRemaining > 0
        ? 'còn khoảng $hoursRemaining giờ'
        : 'hạn chót: ${deadline.day}/${deadline.month}/${deadline.year}';

    await _localNotifications.show(
      id: taskTitle.hashCode,
      title: '⏰ Nhắc nhở hạn chót: Task sắp đến hạn!',
      body: 'Task "$taskTitle" sắp đến hạn ($timeInfo). Hãy kiểm tra và cập nhật tiến độ!',
      notificationDetails: notificationDetails,
      payload: 'task_deadline',
    );
  }

  /// Quét danh sách task và nhắc nhở các task sắp đến hạn trong vòng 24 - 48 giờ (US-059).
  Future<int> checkAndAlertUpcomingDeadlines({
    required List<dynamic> tasks,
    required String currentUserId,
    int warningHours = 48,
  }) async {
    int notifiedCount = 0;
    final now = DateTime.now();

    for (final task in tasks) {
      if (task.assigneeId != currentUserId) continue;
      if (task.status == 'Done') continue;
      if (task.deadline == null) continue;

      final diff = task.deadline!.difference(now);
      // Nếu hạn chót trong khoảng từ 0 đến warningHours giờ tới
      if (diff.inHours >= 0 && diff.inHours <= warningHours) {
        await showTaskDeadlineAlert(
          taskTitle: task.title,
          deadline: task.deadline!,
          hoursRemaining: diff.inHours,
        );
        notifiedCount++;
      }
    }
    return notifiedCount;
  }
}
