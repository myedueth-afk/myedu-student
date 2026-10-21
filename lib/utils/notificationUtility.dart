import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:eschool/app/routes.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/notificationNavigationHandler.dart';
import 'package:eschool/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

// ignore: avoid_classes_with_only_static_members
class NotificationUtility {
  static String generalNotificationType = "general";

  static String assignmentlNotificationType = "assignment";
  static String paymentNotificationType = "payment";
  static String notificationType = "Notification";
  static String messageType = "Message";
  static String studentLeaveType = "student_leave";

  /// Stores pending notification when app is opened from terminated state
  static Map<String, dynamic>? _pendingNotificationData;
  static String? _pendingNotificationType;

  /// Check if there's a pending notification to process
  static bool get hasPendingNotification => _pendingNotificationData != null;

  /// Called from HomeScreen/ParentHomeScreen after app is fully initialized
  static Future<void> processPendingNotification() async {
    if (_pendingNotificationData != null) {
      final data = Map<String, dynamic>.from(_pendingNotificationData!);
      final type = _pendingNotificationType ?? "";

      // Clear before processing to avoid duplicate handling
      _pendingNotificationData = null;
      _pendingNotificationType = null;

      debugPrint('Processing pending notification: type=$type');

      await NotificationNavigationHandler.handleNotificationNavigation(
        type,
        data,
      );
    }
  }

  static Future<void> setUpNotificationService() async {
    try {
      NotificationSettings notificationSettings =
          await FirebaseMessaging.instance.getNotificationSettings();

      //ask for permission
      if (notificationSettings.authorizationStatus ==
              AuthorizationStatus.notDetermined ||
          notificationSettings.authorizationStatus ==
              AuthorizationStatus.denied) {
        notificationSettings =
            await FirebaseMessaging.instance.requestPermission();

        //if permission is provisionnal or authorised
        if (notificationSettings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            notificationSettings.authorizationStatus ==
                AuthorizationStatus.provisional) {
          initNotificationListener();
          // await registerFCMToken();
        }

        //if permission denied
      } else if (notificationSettings.authorizationStatus ==
          AuthorizationStatus.denied) {
        return;
      } else if (notificationSettings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          notificationSettings.authorizationStatus ==
              AuthorizationStatus.provisional) {
        // Permission already granted - initialize and register token
        initNotificationListener();
        // await registerFCMToken();
      }

      // CRITICAL: Check if app was opened from a notification while terminated
      // This handles the case where user taps notification when app is completely killed
      await checkForInitialNotification();
    } catch (e) {
      // Handle Google Play services errors in emulatorliveBusTracking
      debugPrint('Firebase messaging setup failed: $e');
      // Continue without Firebase messaging in emulator
    }
  }

  /// Check if the app was opened from a notification while terminated
  /// This stores the notification data to be processed after app is fully ready
  static Future<void> checkForInitialNotification() async {
    try {
      // Firebase: Check if app was opened from FCM notification
      final RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'App opened from terminated state via Firebase notification: ${initialMessage.data}',
        );

        // Store notification to be processed after home screen is ready
        _pendingNotificationType = initialMessage.data['type'] ?? "";
        _pendingNotificationData = Map<String, dynamic>.from(
          initialMessage.data,
        );
        return;
      }

      // Awesome Notifications: Check if app was opened from local notification
      final ReceivedAction? initialAction = await AwesomeNotifications()
          .getInitialNotificationAction(removeFromActionEvents: true);

      if (initialAction != null) {
        debugPrint(
          'App opened from terminated state via Awesome notification: ${initialAction.payload}',
        );

        final payload = initialAction.payload ?? {};
        final type = payload['type'] ?? "";
        debugPrint("Pending notification TYPE: $type");

        // Store notification to be processed after home screen is ready
        _pendingNotificationType = type;
        _pendingNotificationData = Map<String, dynamic>.from(payload);
      }
    } catch (e) {
      debugPrint('Error checking for initial notification: $e');
    }
  }

  /// Re-check notification permissions and register FCM token if granted
  /// This handles the case where user manually enables notifications in Settings
  static Future<void> recheckNotificationPermissions() async {
    try {
      // Check Firebase Messaging permission status
      NotificationSettings notificationSettings =
          await FirebaseMessaging.instance.getNotificationSettings();

      debugPrint(
        'Rechecking notification permissions: ${notificationSettings.authorizationStatus}',
      );

      // If permission is now granted, initialize and register token
      if (notificationSettings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          notificationSettings.authorizationStatus ==
              AuthorizationStatus.provisional) {
        // Initialize listeners if not already done
        initNotificationListener();

        debugPrint('Notification services re-initialized successfully');
      }
    } catch (e) {
      debugPrint('Failed to recheck notification permissions: $e');
    }
  }

  static void initNotificationListener() {
    try {
      // iOS only: prevent FCM from auto-displaying the system notification
      if (Platform.isIOS) {
        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
      }

      // Initialize Firebase messaging listeners
      FirebaseMessaging.onMessage.listen(foregroundMessageListener);
      FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedAppListener);
    } catch (e) {
      // Handle Google Play services errors in emulator
      debugPrint('Firebase messaging listener setup failed: $e');
    }
  }

  static Future<void> foregroundMessageListener(
    RemoteMessage remoteMessage,
  ) async {
    // await FirebaseMessaging.instance.getToken();

    final type = (remoteMessage.data['type'] ?? "").toString();

    if (type == paymentNotificationType) {
      Future.delayed(Duration(seconds: 5), () {
        if (Get.currentRoute == Routes.confirmPayment) {
          Get.back();
        }
      });
    }

    // Create local notification for foreground messages
    createLocalNotification(dimissable: true, message: remoteMessage);
  }

  static void onMessageOpenedAppListener(RemoteMessage remoteMessage) {
    debugPrint('onMessageOpenedAppListener: ${remoteMessage.data}');
    NotificationNavigationHandler.handleNotificationNavigation(
      remoteMessage.data['type'] ?? "",
      remoteMessage.data,
    );
  }

  static Future<void> initializeAwesomeNotification() async {
    await AwesomeNotifications().initialize('resource://mipmap/ic_launcher', [
      NotificationChannel(
        channelKey: notificationChannelKey,
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        vibrationPattern: highVibrationPattern,
        importance: NotificationImportance.Max,
        playSound: true,
      ),
      NotificationChannel(
        channelKey: 'download_channel',
        channelName: 'Download Notifications',
        channelDescription: 'Notifications for file downloads with progress',
        importance: NotificationImportance.High,
        playSound: false,
        enableVibration: false,
      ),
      NotificationChannel(
        channelKey: 'download_complete_channel',
        channelName: 'Download Complete Notifications',
        channelDescription: 'Shows download completion status',
        importance: NotificationImportance.Max,
        playSound: false,
        enableVibration: false,
      ),
    ]);
  }

  static Future<bool> isLocalNotificationAllowed() async {
    const notificationPermission = Permission.notification;
    final status = await notificationPermission.status;
    return status.isGranted;
  }

  /// Use this method to detect when a new notification or a schedule is created
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    final payload = receivedAction.payload ?? {};
    final type = payload['type'] ?? "";

    // Convert payload to Map<String, dynamic> for proper handling
    final Map<String, dynamic> data = Map<String, dynamic>.from(payload);

    NotificationNavigationHandler.handleNotificationNavigation(type, data);
  }

  // Download notification methods
  static Future<void> showDownloadNotification({
    required int notificationId,
    required String fileName,
    required int progress,
  }) async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) return;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'download_channel',
          title: Utils.getTranslatedLabel(downloadingFileKey),
          body: fileName,
          notificationLayout: NotificationLayout.ProgressBar,
          progress: progress.toDouble(),
          category: NotificationCategory.Progress,
          autoDismissible: false,
          showWhen: true,
        ),
      );
    } catch (e) {
      // Handle notification errors silently
    }
  }

  static Future<void> updateDownloadNotification({
    required int notificationId,
    required String fileName,
    required int progress,
  }) async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) return;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'download_channel',
          title: '${Utils.getTranslatedLabel(downloadingFileKey)} ($progress%)',
          body: fileName,
          notificationLayout: NotificationLayout.ProgressBar,
          progress: progress.toDouble(),
          category: NotificationCategory.Progress,
          autoDismissible: false,
          showWhen: true,
        ),
      );
    } catch (e) {
      // Handle notification errors silently
    }
  }

  static Future<void> showDownloadCompleteNotification({
    required int notificationId,
    required String fileName,
  }) async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) return;

      // Use a different notification ID for completion to avoid conflicts
      final completionNotificationId = notificationId + 1000;

      // First, cancel the progress notification
      try {
        await AwesomeNotifications().dismiss(notificationId);
      } catch (e) {
        // Handle dismissal errors silently
      }

      // Small delay to ensure the progress notification is cancelled
      await Future.delayed(const Duration(milliseconds: 100));

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: completionNotificationId,
          channelKey: 'download_complete_channel',
          title: '${Utils.getTranslatedLabel(downloadCompleteKey)} ✅',
          body:
              '$fileName ${Utils.getTranslatedLabel(fileDownloadedSuccessfullyKey)}',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Status,
          autoDismissible: true,
          showWhen: true,
          wakeUpScreen: false,
          fullScreenIntent: false,
        ),
      );

      // Auto-dismiss the notification after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        try {
          AwesomeNotifications().dismiss(completionNotificationId);
        } catch (e) {
          // Handle dismissal errors silently
        }
      });
    } catch (e) {
      // Handle notification errors silently
    }
  }

  static Future<void> showDownloadErrorNotification({
    required int notificationId,
    required String fileName,
    required String error,
  }) async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) return;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'download_channel',
          title: '${Utils.getTranslatedLabel(downloadFailedKey)} ❌',
          body:
              '${Utils.getTranslatedLabel(failedToDownloadFileKey)} $fileName',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Error,
          autoDismissible: true,
          showWhen: true,
          wakeUpScreen: false,
          fullScreenIntent: false,
        ),
      );

      // Auto-dismiss the notification after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        try {
          AwesomeNotifications().dismiss(notificationId);
        } catch (e) {
          // Handle dismissal errors silently
        }
      });
    } catch (e) {
      // Handle notification errors silently
    }
  }

  static Future<void> createLocalNotification({
    required bool dimissable,
    required RemoteMessage message,
  }) async {
    final String title = message.notification?.title ?? "";
    final String body = message.notification?.body ?? "";
    final String imageUrl = message.data['image'] ?? "";

    // Convert all notification data to Map<String, String> for payload
    // This ensures ALL data fields are preserved (assignment_id, class_subject_id, etc.)
    final Map<String, String> payload = {};
    message.data.forEach((key, value) {
      payload[key] = value.toString();
    });

    // Ensure type field exists (fallback to empty string if not present)
    if (!payload.containsKey('type')) {
      payload['type'] = '';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        title: title,
        body: body,
        id: 1,
        locked: !dimissable,
        payload: payload, // Pass ALL data fields here
        channelKey: notificationChannelKey,
        notificationLayout: NotificationLayout.BigPicture,
        autoDismissible: dimissable,
        bigPicture: imageUrl,
        largeIcon: imageUrl,
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage remoteMessage) async {
  print('onBackgroundMessage: ${remoteMessage.toMap()}');
  if (kDebugMode) {
    debugPrint(remoteMessage.toMap().toString());
  }
  // Background message received - notification will be shown by Firebase
  // Data will be fetched from API when user opens the notification screen
}
