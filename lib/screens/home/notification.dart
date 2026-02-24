import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading notifications: ${snapshot.error}"),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                "No new notifications 🔕",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    // Formatting the date nicely (e.g., "Today, 10:30 AM" or "Oct 24")
    final timeString = DateFormat('MMM d, h:mm a').format(notification.createdAt);

    return GestureDetector(
      onTap: () {
        // Mark as read when tapped
        if (!notification.isRead) {
          _notificationService.markAsRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Slightly dim the card if it has already been read
          color: notification.isRead
              ? const Color(0xFFFFF3C7)
              : const Color(0xFFFFECA1),
          borderRadius: BorderRadius.circular(40),
          // Add a subtle border for unread notifications
          border: notification.isRead
              ? null
              : Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 15.0),
              child: Icon(
                notification.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                size: 30,
                color: notification.isRead ? Colors.black54 : Colors.orange,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}