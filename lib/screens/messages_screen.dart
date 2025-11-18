import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../cubits/message/message_cubit.dart';
import '../cubits/message/message_state.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/custom_skeletons.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    context.read<MessageCubit>().getConversations(context);
  }

  String _getOtherParticipantName(
      List<dynamic> participants, String currentUserId) {
    final otherParticipant = participants.firstWhere(
      (p) => p['_id'] != currentUserId,
      orElse: () => participants.first,
    );
    return '${otherParticipant['firstName']} ${otherParticipant['lastName']}';
  }

  // Méthode pour construire le skeleton de chargement du chat
  Widget _buildChatSkeletonLoading() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                // Alterner les messages à gauche et à droite
                final isRight = index % 2 == 0;
                return Align(
                  alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRight 
                          ? AppColors.buttonColor.withOpacity(0.3) 
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: isRight 
                          ? CrossAxisAlignment.end 
                          : CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(
                          style: SkeletonLineStyle(
                            width: 150 + (index % 3) * 30,
                            height: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SkeletonLine(
                          style: SkeletonLineStyle(
                            width: 80,
                            height: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SkeletonLine(
                  style: SkeletonLineStyle(
                    height: 40,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SkeletonAvatar(
                style: SkeletonAvatarStyle(
                  width: 40,
                  height: 40,
                  isCircle: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is AuthSuccess ? authState.user!['id'] : '';

    return BlocBuilder<MessageCubit, MessageState>(
      builder: (context, state) {
        if (state is MessageInitial) {
          _loadConversations();
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBarWithLogo(
              title: 'Messages',
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return const SkeletonListTile(
                    hasLeading: true,
                    leadingStyle: SkeletonAvatarStyle(
                      width: 48,
                      height: 48,
                      isCircle: true,
                    ),
                    hasTitle: true,
                    titleStyle: SkeletonLineStyle(
                      height: 16,
                      width: 150,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    hasSubtitle: true,
                    subtitleStyle: SkeletonLineStyle(
                      height: 12,
                      width: 200,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  );
                },
              ),
            ),
          );
        }

        if (state is MessageLoading) {
          return Scaffold(
            appBar: AppBarWithLogo(
              title: 'Messages',
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return const SkeletonListTile(
                    hasLeading: true,
                    leadingStyle: SkeletonAvatarStyle(
                      width: 48,
                      height: 48,
                      isCircle: true,
                    ),
                    hasTitle: true,
                    titleStyle: SkeletonLineStyle(
                      height: 16,
                      width: 150,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    hasSubtitle: true,
                    subtitleStyle: SkeletonLineStyle(
                      height: 12,
                      width: 200,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  );
                },
              ),
            ),
          );
        }

        if (state is MessageError) {
          return Scaffold(
            appBar: AppBarWithLogo(
              title: 'Messages',
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.error),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadConversations,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ConversationsLoaded) {
          final conversations = state.conversations;

          if (conversations.isEmpty) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBarWithLogo(
                title: 'Messages',
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is AuthSuccess && 
                        state.user != null && 
                        state.user!['profileImage'] != null) {
                      // Display profile image if available
                      return InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Déconnexion'),
                              content: const Text(
                                  'Voulez-vous vraiment vous déconnecter ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<AuthCubit>().logout();
                                    Navigator.pushReplacementNamed(
                                        context, AppRoutes.login);
                                  },
                                  child: Text(
                                    'Déconnexion',
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(left: 12, top: 10, bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(50),
                            image: DecorationImage(
                              image: NetworkImage(state.user!['profileImage']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Show default person icon if no profile image
                      return InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Déconnexion'),
                              content: const Text(
                                  'Voulez-vous vraiment vous déconnecter ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<AuthCubit>().logout();
                                    Navigator.pushReplacementNamed(
                                        context, AppRoutes.login);
                                  },
                                  child: Text(
                                    'Déconnexion',
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          width: 50,
                          height: 50,
                          child: Icon(Icons.person, color: Colors.grey),
                          margin: const EdgeInsets.only(left: 12, top: 10, bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/nodata.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun message pour le moment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBarWithLogo(
              title: 'Messages',
              automaticallyImplyLeading: false,
              elevation: 0,
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<MessageCubit>().getConversations(context);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: conversations.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final otherParticipantName = _getOtherParticipantName(
                    conversation['participants'],
                    currentUserId,
                  );
                  final unreadCount =
                      conversation['unreadCount'][currentUserId] ?? 0;

                  return InkWell(
                    onTap: () async {
                      final Map<String, dynamic> conversationMap =
                          Map<String, dynamic>.from(conversation);
                      await Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {
                          ...conversationMap,
                          'otherParticipantName': otherParticipantName,
                        },
                      );
                      // Reload conversations when returning
                      if (mounted) {
                        _loadConversations();
                      }
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.buttonColor,
                        child: Text(
                          otherParticipantName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        otherParticipantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        conversation['lastMessage']?['content'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            conversation['lastMessage']?['timestamp'] != null
                                ? DateFormat.jm()
                                    .format(DateTime.parse(conversation['lastMessage']
                                        ['timestamp']))
                                : '',
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBarWithLogo(
            title: 'Messages',
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            elevation: 0,
          ),
          body: const Center(
            child: Text('chargement ...'),
          ),
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Configurer le timer pour rafraîchir toutes les 15 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _loadMessages();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadMessages() {
    context
        .read<MessageCubit>()
        .getConversationMessages(
          context,
          widget.conversation['_id'],
          page: 1,
        )
        .then((_) {
      // Scroll to bottom after messages are loaded
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    // Créer un message temporaire
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      final tempMessage = {
        'content': messageContent,
        'sender': {'_id': authState.user!['id']},
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Mettre à jour l'état local immédiatement
      if (mounted) {
        final currentState = context.read<MessageCubit>().state;
        if (currentState is ConversationMessagesLoaded) {
          final updatedMessages = List<dynamic>.from(currentState.messages)
            ..add(tempMessage);
          context.read<MessageCubit>().emit(
                ConversationMessagesLoaded(
                    updatedMessages, currentState.hasMore),
              );
        }
      }
    }

    // Envoyer le message au serveur
    context.read<MessageCubit>().sendChatMessage(
          content: messageContent,
          context: context,
          conversationId: widget.conversation['_id'],
        );

    // Scroll to bottom after sending message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Méthode pour construire le skeleton de chargement du chat
  Widget _buildChatSkeletonLoading() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                // Alterner les messages à gauche et à droite
                final isRight = index % 2 == 0;
                return Align(
                  alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRight 
                          ? AppColors.buttonColor.withOpacity(0.3) 
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: isRight 
                          ? CrossAxisAlignment.end 
                          : CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(
                          style: SkeletonLineStyle(
                            width: 150 + (index % 3) * 30,
                            height: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SkeletonLine(
                          style: SkeletonLineStyle(
                            width: 80,
                            height: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SkeletonLine(
                  style: SkeletonLineStyle(
                    height: 40,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SkeletonAvatar(
                style: SkeletonAvatarStyle(
                  width: 40,
                  height: 40,
                  isCircle: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is AuthSuccess ? authState.user!['id'] : '';

    return BlocBuilder<MessageCubit, MessageState>(
      builder: (context, state) {
        Widget body;

        if (state is MessageInitial) {
          _loadMessages();
          body = _buildChatSkeletonLoading();
        } else if (state is MessageLoading) {
          body = _buildChatSkeletonLoading();
        } else if (state is MessageError) {
          body = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.error),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadMessages,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        } else if (state is ConversationMessagesLoaded) {
          final messages = List<dynamic>.from(state.messages);
          messages.sort((a, b) {
            DateTime dateA = DateTime.parse(a['createdAt']);
            DateTime dateB = DateTime.parse(b['createdAt']);
            return dateA.compareTo(dateB); // ordre chronologique
          });

          body = Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender']['_id'] == currentUserId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.buttonColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['content'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.jm()
                                  .format(DateTime.parse(message['createdAt'])),
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Écrivez votre message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppColors.buttonColor,
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          body = const Center(child: Text('chargement ...'));
        }

        return Scaffold(
          appBar: AppBarWithLogo(
            title: widget.conversation['otherParticipantName'],
            backgroundColor: Colors.white,
            elevation: 0,
            leading: CircleAvatar(
              backgroundColor: AppColors.buttonColor,
              child: Text(
                widget.conversation['otherParticipantName']
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          body: body,
        );
      },
    );
  }
}
