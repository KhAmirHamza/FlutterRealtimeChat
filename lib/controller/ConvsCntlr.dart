import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:realtime_chat/controller/userController.dart';
import 'package:realtime_chat/model/Conversation.dart';
import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../view/conversation_list_page.dart';

class ConversationController extends GetxController {
  var conversations = <Conversation>[].obs;
  final dio = Dio();

  createConversation(
      BuildContext context,
      IO.Socket socket,
      UserController userController,
      ConversationController convsController,
      User currentUser,
      String id,
      List<User> users,
      List<Message> messages) async {
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.post(
      'http://172.28.240.1:3000/conversation/add',
      data: jsonEncode(<String, dynamic>{
        "users": users,
        "messages": messages,
      }),
      options: Options(headers: header),
    );
    if (response.statusCode == 200) {
      print("Conversation Successfully Added!");

      print("userController");
      print(userController.users.length.toString());
      print(convsController.conversations.length.toString());
      print(socket.id.toString());
      

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => 
              ConversationListPage(userController, convsController, currentUser, socket)
              ));

    }
  }

  sendMessage(String convsId, Message message, IO.Socket socket) async {
    print(message);

    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.post(
      "http://172.28.240.1:3000/conversation/sendMessage?convsId=" + convsId,
      data: jsonEncode(<String, dynamic>{
        '_id': message.id,
        "fromId": message.fromId,
        "toId": message.toId,
        'text': message.text,
        'seenBy': message.seenBy,
        'imageUrl': message.imageUrl,
      }),
      options: Options(headers: header),
    );

    Message messageData = Message.fromJson(response.data);

    if (response.statusCode == 200) {
      var json = {
        "_id": messageData.id,
        "fromId": messageData.fromId,
        "toId": messageData.toId,
        "text": messageData.text,
        "seenBy": messageData.seenBy,
        'imageUrl': message.imageUrl,
      };
      socket.emit('sendMessage', json);
      print("Message Send Successfully!");
    }
  }

  seenMessage(String convsId, String messageId, IO.Socket socket,
      String otherUserId, String currentUserId) async {
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.post(
      "http://172.28.240.1:3000/conversation/seenMessage?convsId=" + convsId,
      data: jsonEncode(<String, dynamic>{
        'messageId': messageId,
        "currentUserId": currentUserId,
      }),
      options: Options(headers: header),
    );
    if (response.statusCode == 200) {
      notifyMessageSeen(socket, otherUserId, currentUserId);
    }
  }

  void notifyMessageSeen(
      IO.Socket socket, String otherUserId, String currentUserId) {
    var json = {"otherUserId": otherUserId, "currentUserId": currentUserId};
    socket.emit('notifyMessageSeen', json);
    conversations.refresh();
  }

  void getConversationByUserId(String userId) async {
    conversations.clear();

    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.get(
      "http://172.28.240.1:3000/conversation/get?userId=${userId}",
      options: Options(headers: header),
    );
    if (response.statusCode == 200) {
      var result = response.data;
      for (int i = 0; i < result.length; i++) {
        Conversation conversation = Conversation.fromJson(result[i]);
        List<User> users = <User>[];
        List<Message> messages = <Message>[];
        conversations.add(conversation);
      }
      print("Conversations: " + result.length.toString());
      conversations.refresh();
    }
  }
}
