import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading.dart';
import '../../auth/application/auth_controller.dart';
import '../application/chat_providers.dart';
import '../domain/chat_message.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  var _sending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatSocketInitProvider));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _textCtrl.text.trim();
    if (content.isEmpty || _sending) return;

    setState(() => _sending = true);
    _textCtrl.clear();

    await ref
        .read(messagesProvider(widget.conversationId).notifier)
        .sendMessage(content);

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final currentUser = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.authBg2,
      appBar: AppBar(
        title: const Text('Chat'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Loading(message: 'Cargando mensajes...'),
              error: (e, _) => EmptyState(
                message: 'No se pudieron cargar los mensajes.',
                icon: Icons.chat_bubble_outline,
                actionLabel: 'Reintentar',
                onAction: () => ref
                    .invalidate(messagesProvider(widget.conversationId)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyState(
                    message: 'Sé el primero en enviar un mensaje.',
                    icon: Icons.chat_bubble_outline,
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUser?.email;
                    final showDate = i == messages.length - 1 ||
                        !_sameDay(
                          messages[i].createdAt,
                          messages[i + 1].createdAt,
                        );
                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        _MessageBubble(message: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _textCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white.withAlpha(230),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 168, 16, 16).withAlpha(20),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withAlpha(179)
                        : AppColors.textHint,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(
                    status: message.status,
                    isOptimistic: message.isOptimistic,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message status icon (✓ / ✓✓ / ✓✓ blue) ──────────────────────────────────

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.isOptimistic});

  final MessageStatus status;
  final bool isOptimistic;

  @override
  Widget build(BuildContext context) {
    if (isOptimistic) {
      return const SizedBox(
        width: 14,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Colors.white54,
        ),
      );
    }

    return switch (status) {
      MessageStatus.read => const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.lightBlueAccent,
        ),
      MessageStatus.delivered => Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white.withAlpha(179),
        ),
      MessageStatus.sent => Icon(
          Icons.done,
          size: 14,
          color: Colors.white.withAlpha(179),
        ),
    };
  }
}

// ── Date divider ──────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  static const _months = [
    '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Hoy';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Ayer';
    } else {
      final m = _months[date.month];
      label = date.year == now.year
          ? '${date.day} $m'
          : '${date.day} $m ${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white24)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          const Expanded(child: Divider(color: Colors.white24)),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withAlpha(20),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              child: sending
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : IconButton(
                      onPressed: onSend,
                      icon: const Icon(Icons.send_rounded),
                      color: AppColors.primary,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withAlpha(30),
                        shape: const CircleBorder(),
                        minimumSize: const Size(40, 40),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
