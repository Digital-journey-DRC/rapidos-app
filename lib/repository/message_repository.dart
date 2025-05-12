import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class MessageRepository {
  static Box? _messagesBox;

  static Future<void> init() async {
    if (!Hive.isBoxOpen("messages")) {
      _messagesBox = await Hive.openBox("messages");
    } else {
      _messagesBox = Hive.box("messages");
    }
  }

  static Future<List<dynamic>> getMessages(String conversationId) async {
    try {
      await init();
      final savedData = _messagesBox?.get(conversationId);
      if (savedData != null) {
        List data = jsonDecode(savedData) as List;
        return data;
      }
      return [];
    } catch (error) {
      print("Error retrieving messages: $error");
      return [];
    }
  }

  static Future<void> saveMessages(String conversationId, List<dynamic> messages) async {
    try {
      await init();
      await _messagesBox?.put(conversationId, jsonEncode(messages));
      print("Messages saved successfully");
    } catch (error) {
      print("Error saving messages: $error");
    }
  }

  static Future<void> addMessage(String conversationId, Map<String, dynamic> message) async {
    try {
      await init();
      var messages = await getMessages(conversationId);
      messages.add(message);
      await saveMessages(conversationId, messages);
    } catch (error) {
      print("Error adding message: $error");
    }
  }
}
