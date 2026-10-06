import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;
  StreamSubscription? _notificationSubscription;

  NotificationBloc({required this.notificationRepository})
      : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<NotificationsUpdated>(_onNotificationsUpdated);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
  }

  void _onLoadNotifications(
      LoadNotifications event, Emitter<NotificationState> emit) {
    print('[NOTIFICATION BLOC] Bắt đầu stream thông báo cho user: ${event.userId}');
    emit(NotificationLoading());
    _notificationSubscription?.cancel();
    _notificationSubscription = notificationRepository
        .streamUserNotifications(event.userId)
        .listen(
      (notifications) {
        add(NotificationsUpdated(notifications));
      },
      onError: (error) {
        print('[NOTIFICATION ERROR] Lỗi stream thông báo trong NotificationBloc: $error');
        if (!isClosed) {
          emit(NotificationError(error.toString()));
        }
      },
    );
  }

  void _onNotificationsUpdated(
      NotificationsUpdated event, Emitter<NotificationState> emit) {
    print('[NOTIFICATION BLOC] Nhận cập nhật ${event.notifications.length} thông báo (chưa đọc: ${event.notifications.where((n) => !n.isRead).length})');
    emit(NotificationLoaded(event.notifications));
  }

  Future<void> _onMarkAsRead(
      MarkAsRead event, Emitter<NotificationState> emit) async {
    try {
      await notificationRepository.markAsRead(event.notificationId);
    } catch (e) {
      // Handle error if needed, for now stream will automatically update UI if success
    }
  }

  Future<void> _onMarkAllAsRead(
      MarkAllAsRead event, Emitter<NotificationState> emit) async {
    try {
      await notificationRepository.markAllAsRead(event.userId);
    } catch (e) {
      // Handle error
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
