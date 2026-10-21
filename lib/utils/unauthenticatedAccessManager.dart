import 'dart:developer';

import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/socketSettingCubit.dart';
import 'package:get/get.dart';

class UnauthenticatedAccessManager {
  /// Singleton instance.
  static final UnauthenticatedAccessManager _instance =
      UnauthenticatedAccessManager._internal();

  /// Factory constructor returns the singleton.
  factory UnauthenticatedAccessManager() => _instance;

  UnauthenticatedAccessManager._internal();

  AuthCubit? _authCubit;
  SocketSettingCubit? _socketSettingCubit;

  String? _lastRoute;

  bool _isHandling = false;

  bool _isLoggedOut = false;

  void init({
    required AuthCubit authCubit,
    SocketSettingCubit? socketSettingCubit,
  }) {
    _authCubit = authCubit;
    _socketSettingCubit = socketSettingCubit;
  }

  bool get isLoggedOut => _isLoggedOut;

  String? get lastRoute => _lastRoute;

  void clearLastRoute() {
    _lastRoute = null;
  }

  void onUserAuthenticated() {
    _isLoggedOut = false;
    log(
      'User re-authenticated. API calls unblocked.',
      name: 'UnauthenticatedAccessManager',
    );
  }

  void handleUnauthorizedAccess() {
    _isLoggedOut = true;

    if (_isHandling) return;
    _isHandling = true;

    log(
      'Unauthorized access detected. Blocking API calls and logging out.',
      name: 'UnauthenticatedAccessManager',
    );

    // Disconnect WebSocket to stop background communication
    _disconnectWebSocket();

    // Save current route for redirect after re-login
    _saveCurrentRoute();

    // Sign out — clears tokens, session data, emits Unauthenticated
    _authCubit?.signOut();

    // Navigate to auth screen, clearing the entire navigation stack
    Get.offNamedUntil(Routes.auth, (_) => false);

    _isHandling = false;
  }

  /// Disconnects the WebSocket connection gracefully.
  void _disconnectWebSocket() {
    try {
      _socketSettingCubit?.disconnect();
      log(
        'WebSocket disconnected.',
        name: 'UnauthenticatedAccessManager',
      );
    } catch (e) {
      log(
        'Failed to disconnect WebSocket: $e',
        name: 'UnauthenticatedAccessManager',
      );
    }
  }

  /// Saves the current route for post-login redirect.
  void _saveCurrentRoute() {
    try {
      _lastRoute = Get.currentRoute;
      log(
        'Saved last route: $_lastRoute',
        name: 'UnauthenticatedAccessManager',
      );
    } catch (e) {
      log(
        'Failed to get current route: $e',
        name: 'UnauthenticatedAccessManager',
      );
      _lastRoute = null;
    }
  }
}
