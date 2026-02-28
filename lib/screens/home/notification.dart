import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../recipe/view_recipe.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];

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
              child: Text("❌ Error: ${snapshot.error}"),
            );
          }

          if (snapshot.hasData) {
            _notifications = snapshot.data!;
          }

          final notifications = _notifications;

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
              // 🔥 Fixed: Passing context to the card builder
              return _buildNotificationCard(notification, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
      NotificationModel notification,
      BuildContext context,
      ) {
    final timeString =
    DateFormat('MMM d, h:mm a').format(notification.createdAt);

    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          _notificationService.markAsRead(notification.id);
        }

        if (notification.recipeId != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );

          final db = DatabaseService();
          final recipe =
          await db.getRecipeById(notification.recipeId!);

          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          if (recipe != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ViewRecipePage(recipe: recipe),
              ),
            );
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                    Text('Recipe is no longer available')),
              );
            }
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: notification.isRead
              ? const Color(0xFFFFF3C7)
              : const Color(0xFFFFECA1),
          borderRadius: BorderRadius.circular(30),
          border: notification.isRead
              ? null
              : Border.all(
            color: Colors.orange.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  notification.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  size: 28,
                  color: notification.isRead
                      ? Colors.black54
                      : Colors.orange,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await _notificationService
                        .deleteNotification(notification.id);

                    setState(() {
                      _notifications.removeWhere(
                              (n) => n.id == notification.id);
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead
                    ? FontWeight.w600
                    : FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeString,
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}