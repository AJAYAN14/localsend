import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';

final _logger = Logger('ForegroundService');

/// Provider that manages the Android foreground service for background file transfer.
/// On non-Android platforms, all methods are no-ops.
final foregroundServiceProvider = NotifierProvider<ForegroundServiceNotifier, bool>(
  (ref) => ForegroundServiceNotifier(),
);

class ForegroundServiceNotifier extends PureNotifier<bool> {
  bool _initialized = false;

  @override
  bool init() => false; // false = service not running

  /// Initializes the foreground task configuration.
  /// Must be called once before starting the service.
  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'localsend_file_transfer',
        channelName: t.foregroundService.channelName,
        channelDescription: t.foregroundService.channelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Starts the foreground service for file transfer.
  /// Shows a persistent notification with the given [title].
  Future<void> startTransferService({required String title}) async {
    if (!checkPlatform([TargetPlatform.android])) return;
    if (state) return; // already running

    try {
      _ensureInitialized();

      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.dataSync],
        notificationTitle: title,
        notificationText: t.foregroundService.preparing,
      );

      state = true;
      _logger.info('Foreground service started: $title');
    } catch (e) {
      _logger.warning('Failed to start foreground service', e);
    }
  }

  /// Updates the notification with current transfer progress.
  Future<void> updateProgress({
    required String fileName,
    required int percent,
    required bool isSending,
  }) async {
    if (!state) return; // service not running

    try {
      final title = isSending ? t.foregroundService.sending : t.foregroundService.receiving;
      final text = '$fileName - $percent%';

      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } catch (e) {
      // Silently ignore update failures to avoid spamming logs
    }
  }

  /// Stops the foreground service.
  /// If [showCompletion] is true, shows a "Transfer Complete" notification
  /// before stopping (with a brief delay so the user can see it).
  Future<void> stopTransferService({bool showCompletion = false}) async {
    if (!state) return;

    try {
      if (showCompletion) {
        // Update notification to show completion message
        await FlutterForegroundTask.updateService(
          notificationTitle: t.foregroundService.completed,
          notificationText: t.foregroundService.completedBody,
        );
        // Brief delay so user can see the completion notification
        await Future.delayed(const Duration(seconds: 3));
      }

      await FlutterForegroundTask.stopService();
      state = false;
      _logger.info('Foreground service stopped');
    } catch (e) {
      _logger.warning('Failed to stop foreground service', e);
    }
  }
}
