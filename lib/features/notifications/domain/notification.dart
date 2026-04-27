enum NotificationType {
  chatMessage,
  reservationRequested,
  reservationAccepted,
  reservationRejected,
  routeDeleted,
  unknown;

  static NotificationType fromString(String? s) => switch (s?.toUpperCase()) {
        'CHAT_MESSAGE' => chatMessage,
        'RESERVATION_REQUESTED' => reservationRequested,
        'RESERVATION_ACCEPTED' => reservationAccepted,
        'RESERVATION_REJECTED' => reservationRejected,
        'ROUTE_DELETED' => routeDeleted,
        _ => unknown,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}
