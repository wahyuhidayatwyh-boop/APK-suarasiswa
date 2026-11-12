import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/notification_model.dart';
import '../../auth/presentation/auth_controller.dart';

abstract class NotificationRepository {
  Future<ApiResponse<List<NotificationModel>>> getNotifications();
  Future<ApiResponse<bool>> markAsRead(String id);
  Future<ApiResponse<bool>> markAllAsRead();
  Future<ApiResponse<bool>> deleteNotification(String id);
  Future<ApiResponse<bool>> deleteAllNotifications();
}

class ApiNotificationRepository implements NotificationRepository {
  final ApiClient _apiClient;

  ApiNotificationRepository(this._apiClient);

  @override
  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    return await _apiClient.get<List<NotificationModel>>(
      ApiEndpoints.notifications,
      fromJsonT: (data) =>
          (data as List).map((item) => NotificationModel.fromJson(item)).toList(),
    );
  }

  @override
  Future<ApiResponse<bool>> markAsRead(String id) async {
    return await _apiClient.patch<bool>(
      ApiEndpoints.notificationRead(id),
      fromJsonT: (_) => true,
    );
  }

  @override
  Future<ApiResponse<bool>> markAllAsRead() async {
    return await _apiClient.post<bool>(
      ApiEndpoints.notificationReadAll,
      fromJsonT: (_) => true,
    );
  }

  @override
  Future<ApiResponse<bool>> deleteNotification(String id) async {
    return await _apiClient.delete<bool>(
      ApiEndpoints.notificationDetail(id),
      fromJsonT: (_) => true,
    );
  }

  @override
  Future<ApiResponse<bool>> deleteAllNotifications() async {
    return await _apiClient.delete<bool>(
      ApiEndpoints.notifications,
      fromJsonT: (_) => true,
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ApiNotificationRepository(ref.watch(apiClientProvider));
});

final notificationsFutureProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  final response = await repo.getNotifications();
  if (response.success && response.data != null) {
    return response.data!;
  }
  return [];
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsFutureProvider).valueOrNull ?? [];
  return notifs.where((n) => !n.isRead).length;
});
