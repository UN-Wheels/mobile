import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading.dart';
import '../application/chat_providers.dart';
import '../domain/conversation.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  @override
  void initState() {
    super.initState();
    // Trigger socket connection
    Future.microtask(() => ref.read(chatSocketInitProvider));
  }

  @override
  Widget build(BuildContext context) {
    final convsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: convsAsync.when(
        loading: () => const Loading(message: 'Cargando conversaciones...'),
        error: (e, _) => EmptyState(
          message: 'No se pudieron cargar los mensajes.',
          icon: Icons.chat_bubble_outline,
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(conversationsProvider),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyState(
              message: 'No tienes conversaciones aún.\n'
                  'Reserva un viaje o acepta pasajeros para chatear.',
              icon: Icons.chat_bubble_outline,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(conversationsProvider.future),
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 72,
                color: Colors.white12,
              ),
              itemBuilder: (context, i) => _ConversationTile(
                conversation: conversations[i],
                onTap: () => context.push(
                  RouteNames.chatDetailOf(conversations[i].id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDriver = conversation.otherUserRole == 'driver';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDriver
                    ? AppColors.primary.withAlpha(40)
                    : AppColors.secondary.withAlpha(60),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  conversation.initials,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDriver ? AppColors.primary : AppColors.primaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessageAt != null)
                        Text(
                          timeago.format(
                            conversation.lastMessageAt!,
                            locale: 'es',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessageText ?? 'Sin mensajes aún',
                    style: TextStyle(
                      fontSize: 13,
                      color: conversation.lastMessageText != null
                          ? Colors.white70
                          : Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread badge
            if (conversation.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCount > 99 ? '99+' : conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
