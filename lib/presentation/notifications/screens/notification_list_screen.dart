import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/notification_model.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../../../app/utils/date_formatter.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  String _formatTime(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.hour)}:${two(date.minute)} - ${formatDateVi(date)}';
  }

  void _onNotificationTap(BuildContext context, NotificationModel notification) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(MarkAsRead(notification.id));
    }

    // Điều hướng (Navigation) dựa vào type và targetId
    // TODO: Bổ sung logic điều hướng tuỳ thuộc vào NotificationType
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã bấm vào: ${notification.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated
        ? authState.user.id
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả là đã đọc',
            onPressed: () {
              context.read<NotificationBloc>().add(MarkAllAsRead(userId));
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationLoaded) {
            final notifications = state.notifications;
            if (notifications.isEmpty) {
              return const Center(child: Text('Không có thông báo nào.'));
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  tileColor: notification.isRead ? null : Colors.blue.withValues(alpha: 0.1),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        child: Icon(_getIconForType(notification.type)),
                      ),
                      if (!notification.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.body),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () => _onNotificationTap(context, notification),
                );
              },
            );
          }

          if (state is NotificationError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          }

          return const SizedBox();
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'ASSIGN_TASK':
        return Icons.assignment_ind;
      case 'STATUS_CHANGE':
        return Icons.swap_horiz;
      case 'NEW_COMMENT':
        return Icons.comment;
      case 'STORY_ADDED':
        return Icons.post_add;
      case 'PROJECT_UPDATED':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }
}
