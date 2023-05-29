import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:realtime_chat/controller/userController.dart';
import 'package:realtime_chat/model/Conversation.dart';
import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:realtime_chat/view/create_group.dart';
import 'package:realtime_chat/view/group_chat_widget.dart';
import 'package:realtime_chat/view/p_to_p_chat_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../view/home_page.dart';

class ConversationController extends GetxController {
  var conversations = <Conversation>[].obs;
  final dio = Dio();

  createSingleConversation(
      BuildContext context,
      IO.Socket socket,
      UserController userController,
      ConversationController convsController,
      User currentUser, User selectedUser,
      String id,
      String title,
      String type,
      List<User> users,
      List<Message> messages) async {

    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.post(
      'https://nodejsrealtimechat.onrender.com/conversation/add',
     // 'http://172.28.240.1:3000/conversation/add',
      data: jsonEncode(<String, dynamic>{
        "title": title,
        "type": type,
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

      var result = response.data;
      Conversation conversation = Conversation.fromJson(result);
      conversations.add(conversation);
      print("Conversations: " + result.length.toString());
      conversations.refresh();


      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
              HomePage(userController, currentUser, socket, convsController)
          //  MessageListPage(convsController, currentUser, selectedUser, socket)
              ));
    }
  }

  createGroupConversation(
      BuildContext context,
      IO.Socket socket,
      UserController userController,
      ConversationController convsController,
      User currentUser,
      String id,
      String title,
      String type,
      List<User> users,
      List<Message> messages) async {

    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.post(
      'https://nodejsrealtimechat.onrender.com/conversation/add',
      // 'http://172.28.240.1:3000/conversation/add',
      data: jsonEncode(<String, dynamic>{
        "title": title,
        "type": type,
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
            HomePage(userController, currentUser, socket, convsController)
          ));
    }
  }

  sendMessage(String convsId, String convsType,  Message message, int conversationIndex, IO.Socket socket) async {
    print(message);

    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.post(
     // "http://172.28.240.1:3000/conversation/sendMessage?convsId=" + convsId,
      "https://nodejsrealtimechat.onrender.com/conversation/sendMessage?convsId=" + convsId,
      data: jsonEncode(<String, dynamic>{
        '_id': message.id,
        "from": message.from,
        "to": message.to,
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
        "from": messageData.from,
        "to": messageData.to,
        "convsId": convsId,
        "convsType": convsType,
        "text": messageData.text,
        "seenBy": messageData.seenBy,
        'imageUrl': messageData.imageUrl,
        'createdAt': messageData.createdAt,
        'updatedAt': messageData.updatedAt,
      };


      conversations[conversationIndex].messages!.add(messageData);
      conversations.refresh();

      socket.emit('sendMessage', json);
      print("Message Send Successfully!");
    }
  }

  seenMessage(String convsId, String convsType, String messageId, IO.Socket socket, String currentUserId) async {
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    int currentUserCount = 0;
    for(int i=0; i<conversations[conversations.length-1].messages![conversations[conversations.length-1].messages!.length-1].seenBy!.length; i++){
      if(conversations[conversations.length-1].messages![conversations[conversations.length-1].messages!.length-1].seenBy![i]==currentUserId){
        currentUserCount++;
      }
    }
    //if(currentUserCount>1){
    var response = await dio.post(
      "https://nodejsrealtimechat.onrender.com/conversation/seenMessage?convsId=" + convsId,
     // "http://172.28.240.1:3000/conversation/seenMessage?convsId=" + convsId,
      data: jsonEncode(<String, dynamic>{
        'messageId': messageId,
        "currentUserId": currentUserId,
      }),
      options: Options(headers: header),
    );
    if (response.statusCode == 200) {
      notifyMessageSeen(socket, convsId, convsType, currentUserId);

    }
   // }
  }

  void notifyMessageSeen(
      IO.Socket socket, String convsId, String convsType, String currentUserId) {


    print("notify other client that MessageSeen called");

    var json = {"convsId": convsId,"convsType": convsType, "newUserId": currentUserId};
    socket.emit('notifyMessageSeen', json);

  }

  void getConversationByUserId(String userId) async {


    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.get(
      "https://nodejsrealtimechat.onrender.com/conversation/get?userId=${userId}",
    //  "http://172.28.240.1:3000/conversation/get?userId=${userId}",
      options: Options(headers: header),
    );
    if (response.statusCode == 200) {
      var result = response.data;


      conversations.clear();
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
