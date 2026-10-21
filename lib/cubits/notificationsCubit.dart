import 'package:eschool/data/models/notification.dart';
import 'package:eschool/data/repositories/notificationRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsFetchInProgress extends NotificationsState {}

class NotificationsFetchSuccess extends NotificationsState {
  final List<Notification> notifications;
  final int totalPage;
  final int currentPage;
  final int total;
  final bool moreNotificationsFetchError;
  final bool fetchMoreNotificationsInProgress;

  NotificationsFetchSuccess({
    required this.notifications,
    required this.totalPage,
    required this.currentPage,
    required this.total,
    required this.moreNotificationsFetchError,
    required this.fetchMoreNotificationsInProgress,
  });

  NotificationsFetchSuccess copyWith({
    List<Notification>? newNotifications,
    int? newTotalPage,
    int? newCurrentPage,
    int? newTotal,
    bool? newMoreNotificationsFetchError,
    bool? newFetchMoreNotificationsInProgress,
  }) {
    return NotificationsFetchSuccess(
      notifications: newNotifications ?? notifications,
      totalPage: newTotalPage ?? totalPage,
      currentPage: newCurrentPage ?? currentPage,
      total: newTotal ?? total,
      moreNotificationsFetchError:
          newMoreNotificationsFetchError ?? moreNotificationsFetchError,
      fetchMoreNotificationsInProgress: newFetchMoreNotificationsInProgress ??
          fetchMoreNotificationsInProgress,
    );
  }
}

class NotificationsFetchFailure extends NotificationsState {
  final String errorMessage;

  NotificationsFetchFailure(this.errorMessage);
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository _notificationRepository;

  NotificationsCubit(this._notificationRepository)
      : super(NotificationsInitial());

  /// Fetch initial notifications
  Future<void> fetchNotifications() async {
    try {
      emit(NotificationsFetchInProgress());

      final result = await _notificationRepository.fetchNotifications();

      emit(
        NotificationsFetchSuccess(
          notifications: result['notifications'],
          totalPage: result['totalPage'],
          currentPage: result['currentPage'],
          total: result['total'],
          moreNotificationsFetchError: false,
          fetchMoreNotificationsInProgress: false,
        ),
      );
    } catch (e) {
      emit(NotificationsFetchFailure(e.toString()));
    }
  }

  /// Check if there are more pages to load
  bool hasMore() {
    if (state is NotificationsFetchSuccess) {
      final currentState = state as NotificationsFetchSuccess;
      return currentState.currentPage < currentState.totalPage;
    }
    return false;
  }

  /// Fetch more notifications for pagination
  Future<void> fetchMoreNotifications() async {
    if (state is NotificationsFetchSuccess) {
      final currentState = state as NotificationsFetchSuccess;

      // Prevent multiple simultaneous fetch requests
      if (currentState.fetchMoreNotificationsInProgress) {
        return;
      }

      // Check if there are more pages
      if (!hasMore()) {
        return;
      }

      try {
        emit(currentState.copyWith(
          newFetchMoreNotificationsInProgress: true,
          newMoreNotificationsFetchError: false,
        ));

        // Fetch next page
        final moreNotificationsResult =
            await _notificationRepository.fetchNotifications(
          page: currentState.currentPage + 1,
        );

        // Merge new notifications with existing ones
        final updatedNotifications = List<Notification>.from(
          currentState.notifications,
        )..addAll(moreNotificationsResult['notifications']);

        emit(
          NotificationsFetchSuccess(
            notifications: updatedNotifications,
            totalPage: moreNotificationsResult['totalPage'],
            currentPage: moreNotificationsResult['currentPage'],
            total: moreNotificationsResult['total'],
            moreNotificationsFetchError: false,
            fetchMoreNotificationsInProgress: false,
          ),
        );
      } catch (e) {
        emit(
          currentState.copyWith(
            newFetchMoreNotificationsInProgress: false,
            newMoreNotificationsFetchError: true,
          ),
        );
      }
    }
  }

  /// Retry fetching more notifications after an error
  void retryFetchMore() {
    if (state is NotificationsFetchSuccess) {
      final currentState = state as NotificationsFetchSuccess;
      if (currentState.moreNotificationsFetchError) {
        fetchMoreNotifications();
      }
    }
  }
}
