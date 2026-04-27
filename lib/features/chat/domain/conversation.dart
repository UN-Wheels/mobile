class Conversation {
  const Conversation({
    required this.id,
    required this.routeId,
    required this.otherUserId,
    required this.otherUserRole,
    required this.otherUserName,
    this.bookingId,
    required this.status,
    this.lastMessageText,
    this.lastMessageAt,
    required this.unreadCount,
    required this.updatedAt,
  });

  final String id;
  final String routeId;
  final String otherUserId;
  final String otherUserRole; // 'driver' | 'passenger'
  final String otherUserName;
  final String? bookingId;
  final String status; // 'ACTIVE' | 'ARCHIVED' | 'CLOSED'
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime updatedAt;

  String get displayName {
    if (otherUserName.isNotEmpty) return otherUserName;
    // Fall back to the local part of the email if otherUserId looks like one
    if (otherUserId.contains('@')) return otherUserId.split('@').first;
    return otherUserId.isNotEmpty ? otherUserId : (otherUserRole == 'driver' ? 'Conductor' : 'Pasajero');
  }

  String get initials {
    final name = displayName;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // The backend may return the other user's name in several shapes
    final otherUser = json['otherUser'];
    final otherUserName = (json['otherUserName'] as String?) ??
        (otherUser is Map<String, dynamic>
            ? ((otherUser['name'] ?? otherUser['fullName'] ?? otherUser['full_name'] ?? '') as String)
            : '');

    return Conversation(
      id: (json['conversationId'] ?? json['_id'] ?? json['id'])?.toString() ?? '',
      routeId: (json['routeId'] ?? '').toString(),
      otherUserId: (json['otherUserId'] ?? '').toString(),
      otherUserRole: (json['otherUserRole'] as String?) ?? 'passenger',
      otherUserName: otherUserName,
      bookingId: json['bookingId']?.toString(),
      status: (json['status'] as String?) ?? 'ACTIVE',
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      unreadCount: ((json['unreadCount']) as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Conversation copyWith({
    int? unreadCount,
    String? lastMessageText,
    DateTime? lastMessageAt,
  }) =>
      Conversation(
        id: id,
        routeId: routeId,
        otherUserId: otherUserId,
        otherUserRole: otherUserRole,
        otherUserName: otherUserName,
        bookingId: bookingId,
        status: status,
        lastMessageText: lastMessageText ?? this.lastMessageText,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        updatedAt: updatedAt,
      );
}
