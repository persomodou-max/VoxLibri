import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/constants.dart';

/// Service de notifications locales pour la lecture en arrière-plan.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialise le canal de notification (Android).
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: 'Contrôles de lecture audio des documents PDF',
      importance: Importance.low,
      playSound: false,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Affiche une notification persistante avec le titre du document.
  Future<void> showPlaybackNotification({
    required int id,
    required String title,
    required bool isPlaying,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: 'Lecture en cours',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showWhen: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'prev',
          'Précédent',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          isPlaying ? 'pause' : 'play',
          isPlaying ? 'Pause' : 'Lecture',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'next',
          'Suivant',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'stop',
          'Arrêter',
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    await _plugin.show(
      id,
      AppConstants.appName,
      title,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Supprime la notification de lecture.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Supprime toutes les notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
