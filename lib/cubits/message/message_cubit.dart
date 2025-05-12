import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../cubit/auth_cubit.dart';
import 'message_state.dart';
import '../../services/message_service.dart';
import '../../repository/message_repository.dart';

class MessageCubit extends Cubit<MessageState> {
  final String baseUrl = 'http://68.183.30.146:8000';
  final MessageService _messageService = MessageService();

  MessageCubit() : super(MessageInitial());

  // Récupérer toutes les conversations
  Future<void> getConversations(BuildContext context) async {
    try {
      emit(MessageLoading());

      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.token == null) {
        emit(MessageError('Vous devez être connecté pour voir vos conversations'));
        return;
      }

      _messageService.setAuthToken(authState.token!);
      final data = await _messageService.getConversations();
      
      if (data['success'] == true && data['data'] != null) {
        emit(ConversationsLoaded(data['data']));
      } else {
        emit(MessageError('Erreur lors du chargement des conversations'));
      }
    } catch (e) {
      emit(MessageError('Une erreur est survenue: ${e.toString()}'));
    }
  }

  // Récupérer les messages d'une conversation
  Future<void> getConversationMessages(BuildContext context, String conversationId, {int page = 1}) async {
    try {
      emit(MessageLoading());

      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.token == null) {
        emit(MessageError('Vous devez être connecté pour voir les messages'));
        return;
      }

      _messageService.setAuthToken(authState.token!);
      
      // D'abord, charger les messages du cache
      final cachedMessages = await MessageRepository.getMessages(conversationId);
      if (cachedMessages.isNotEmpty) {
        emit(ConversationMessagesLoaded(cachedMessages, false));
      }

      // Ensuite, charger les messages du serveur
      final data = await _messageService.getConversationMessages(conversationId, page: page);
      
      if (data['success'] == true && data['data'] != null) {
        // Sauvegarder les messages dans le cache
        await MessageRepository.saveMessages(conversationId, data['data']);
        emit(ConversationMessagesLoaded(data['data'], data['hasMore'] ?? false));
      } else {
        emit(MessageError('Erreur lors du chargement des messages'));
      }
    } catch (e) {
      emit(MessageError('Une erreur est survenue: ${e.toString()}'));
    }
  }

  Future<void> sendChatMessage({
    required String content,
    required String conversationId,
    required BuildContext context,
  }) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess ||
          authState.token == null ||
          authState.user == null) {
        emit(MessageError('Vous devez être connecté pour envoyer un message'));
        return;
      }

      final String token = authState.token!;

      // Envoyer le message au serveur silencieusement
      final messageResponse = await http.post(
        Uri.parse('$baseUrl/api/v1/messages/conversations/$conversationId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "content": content,
          "type": "text",
          "attachments": []
        }),
      );

      if (messageResponse.statusCode != 200 && messageResponse.statusCode != 201) {
        // En cas d'erreur, on peut afficher une notification ou un snackbar
        print('Erreur lors de l\'envoi du message au serveur');
      }

    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
    }
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
    required String listingId,
    required BuildContext context,
  }) async {
    try {
      emit(MessageLoading());

      // Get the token and user info from AuthCubit
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess ||
          authState.token == null ||
          authState.user == null) {
        emit(MessageError('Vous devez être connecté pour envoyer un message'));
        return;
      }

      final String userId = authState.user!['id'];
      final String token = authState.token!;

      // First, create or get the conversation
      final conversationResponse = await http.post(
        Uri.parse('$baseUrl/api/v1/messages/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'participants': [receiverId, userId],
          'type': 'direct',
          'metadata': {'listingId': listingId}
        }),
      );

      if (conversationResponse.statusCode != 200 &&
          conversationResponse.statusCode != 201) {
        emit(MessageError(
            'Erreur lors de la création de la conversation: ${conversationResponse.body}'));
        return;
      }

      final conversationData = json.decode(conversationResponse.body);
      if (conversationData['success'] == true && conversationData['data'] != null) {
        final String conversationId = conversationData['data']['_id'];

        // Then send the message
        final messageResponse = await http.post(
          Uri.parse(
              '$baseUrl/api/v1/messages/conversations/$conversationId/messages'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            "content": content,
            "type": "text",
            "attachments": [
              {"type": "image", "url": "string", "name": "string"}
            ]
          }),
        );

        if (messageResponse.statusCode == 200 ||
            messageResponse.statusCode == 201) {
          final messageData = json.decode(messageResponse.body);
          if (messageData['success'] == true) {
            emit(MessageSuccess('Message envoyé avec succès'));
          } else {
            emit(MessageError('Erreur lors de l\'envoi du message'));
          }
        } else {
          emit(MessageError(
              'Erreur lors de l\'envoi du message: ${messageResponse.body}'));
        }
      } else {
        emit(MessageError('Erreur lors de la création de la conversation'));
      }
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }
}
