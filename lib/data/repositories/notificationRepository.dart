import 'package:eschool/data/models/notification.dart';
import 'package:eschool/utils/api.dart';
import 'package:flutter/foundation.dart';

class NotificationRepository {
  /// Fetch notifications from API with pagination support
  Future<Map<String, dynamic>> fetchNotifications({
    int? page,
  }) async {
    try {
      Map<String, dynamic> queryParameters = {};

      if (page != null && page > 0) {
        queryParameters['page'] = page;
      }

      if (kDebugMode) {
        debugPrint('Fetching notifications with params: $queryParameters');
      }

      final result = await Api.get(
        url: Api.notifications,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      if (kDebugMode) {
        debugPrint('Notifications API response: $result');
      }

      // Handle both response formats:
      // 1. Paginated: {data: {data: [...], last_page: x, current_page: y, total: z}}
      // 2. Direct array: {data: [...]}
      final data = result['data'];

      List<dynamic> notificationsList;
      int totalPage;
      int currentPage;
      int total;

      if (data is List) {
        // Direct array format
        notificationsList = data;
        totalPage = 1;
        currentPage = 1;
        total = data.length;
      } else if (data is Map<String, dynamic>) {
        // Paginated format
        notificationsList = (data['data'] as List?) ?? [];
        totalPage = (data['last_page'] as int?) ?? 1;
        currentPage = (data['current_page'] as int?) ?? 1;
        total = (data['total'] as int?) ?? notificationsList.length;
      } else {
        throw ApiException('Unexpected response format');
      }

      return {
        'notifications': notificationsList
            .map((e) => Notification.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        'totalPage': totalPage,
        'currentPage': currentPage,
        'total': total,
      };
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error fetching notifications: $e');
        debugPrint('Stack trace: $st');
      }
      throw ApiException(e.toString());
    }
  }
}
