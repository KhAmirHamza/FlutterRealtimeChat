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
import 'SocketController.dart';


class ConversationController extends GetxController implements SocketListeners{

  var conversations = <Conversation>[].obs;
  final dio = Dio();

  SocketController socketController = new SocketController();


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

      socket.clearListeners();
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

      socket.clearListeners();

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
            HomePage(userController, currentUser, socket, convsController)
          ));
    }
  }

  sendMessage(String convsId, String convsType,  Message message, int conversationIndex){
    socketController.notifyMessageSend(convsId, convsType, message, conversationIndex, this);
  }

  addReactUpdateConvs(int convsIndex, int messageIndex, String convsId, String convsType, String messageId, String reactTitle, IO.Socket socket, String currentUserId) async {
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
      var response = await dio.post(
        "https://nodejsrealtimechat.onrender.com/conversation/reactMessage?convsId=" + convsId,
        data: jsonEncode(<String, dynamic>{
          'messageId': messageId,
          "reactTitle": reactTitle,
          "currentUserId": currentUserId,
        }),
        options: Options(headers: header),
      );
      if (response.statusCode == 200) {
        React react = React(title: reactTitle, userId: currentUserId);

        socketController.notifyNewReactAdded(convsId, messageId, convsType, reactTitle, currentUserId);
        conversations[convsIndex].messages![messageIndex].reacts!.add(react);
        conversations.refresh();
      }
  }


  receivedMessage(String convsId, String convsType, String messageId, IO.Socket socket, String currentUserId) async {
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };

    var response = await dio.post(
      "https://nodejsrealtimechat.onrender.com/conversation/receivedMessage?convsId=" + convsId,
      // "http://172.28.240.1:3000/conversation/seenMessage?convsId=" + convsId,
      data: jsonEncode(<String, dynamic>{
        'messageId': messageId,
        "currentUserId": currentUserId,
      }),
      options: Options(headers: header),
    );
    if (response.statusCode == 200) {
      socketController.notifyMessageReceived(convsId, convsType, currentUserId);
    }
  }

  seenMessage(String convsId, String convsType, String messageId, IO.Socket socket, String currentUserId) async {
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };

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
      socketController.notifyMessageSeen(convsId, convsType, currentUserId);
    }
  }


  void getConversationByUserId(String userId) async {


    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.get(
      "https://nodejsrealtimechat.onrender.com/conversation/get?userId=${userId}",
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



  @override
  void onMessageReceived(IO.Socket socket, data) {
    // TODO: implement onMessageReceived

    var jsonMap = data as Map<String, dynamic>;
    print("Other User Has Received Message: "+jsonMap.toString());

    int convsIndex = 0;
    for(int i=0; i< conversations.length; i++){
      if(conversations[i].id == jsonMap['convsId']) {
        convsIndex = i;
        break;
      }
    }
    if (!conversations[convsIndex]
        .messages![conversations[convsIndex]
        .messages!.length -
        1]
        .receivedBy!.contains(jsonMap['newUserId'])) {

      conversations[convsIndex]
          .messages![conversations[convsIndex]
          .messages!.length -
          1]
          .receivedBy!
          .add(jsonMap['newUserId']);
      conversations.refresh();
    }
  }

  @override
  void onMessageSeen(IO.Socket socket, data) {
    var jsonMap = data as Map<String, dynamic>;
    print("Other User Has Seen Message: "+jsonMap.toString());

    int convsIndex = 0;
    for(int i=0; i< conversations.length; i++){
      if(conversations[i].id == jsonMap['convsId']) {
        convsIndex = i;
        break;
      }
    }
    if (!conversations[convsIndex]
        .messages![conversations[convsIndex]
        .messages!.length -
        1]
        .seenBy!.contains(jsonMap['newUserId'])) {

      conversations[convsIndex]
          .messages![conversations[convsIndex]
          .messages!.length -
          1]
          .seenBy!
          .add(jsonMap['newUserId']);
      conversations.refresh();
    }
  }

  @override
  void onMessageSend(IO.Socket socket, data, User currentUser) {
    // TODO: implement onMessageSend

    var jsonMap = data as Map<String, dynamic>;
    User user = User.fromJson(jsonMap['from']);

    if (user.id!=  currentUser.id!) {
      var receivedByList = jsonMap['receivedBy'].toList();
      var reactList = jsonMap['reacts'].toList();
      List<String> seenBy = <String>[];
      List<String> receivedBy = <String>[];
      List<React> reacts = <React>[];

      for (var i = 0; i < receivedByList.length; i++) {
        //Convert And Reasign Existing SeenBy Data...
        receivedBy.add(receivedByList[i]);
      }

      for (var i = 0; i < reacts.length; i++) {
        //Convert And Reasign Existing SeenBy Data...
        reacts.add(reacts[i]);
      }

      int convsIndex = 0;
      for (int i = 0; i < conversations.length; i++) {
        if (conversations[i].id ==
            jsonMap['convsId']) {
          convsIndex = i;
          break;
        }
      }

      Message message = Message(
          id: jsonMap['id'],
          from: User.fromJson(jsonMap['from']),
          to: jsonMap['to'],
          text: jsonMap['text'],
          seenBy: seenBy,
          receivedBy: receivedBy,
          imageUrl: jsonMap['imageUrl'],
          reacts: reacts,
          createdAt: jsonMap['createdAt'],
          updatedAt: jsonMap['updatedAt']
      );

      if (!(message.receivedBy!.contains(currentUser.id!))) {
        message.receivedBy!.add(currentUser.id!);
        conversations[ convsIndex].messages!.add( message );
        receivedMessage(
            jsonMap['convsId'], jsonMap['convsType'], jsonMap['id'],
            socket,currentUser.id!);
        conversations.refresh();
      }
    }
  }

  @override
  void onNewReactAdded(IO.Socket socket, data) {
    // TODO: implement onNewReactAdded
    var jsonMap = data as Map<String, dynamic>;
    print("A User Has Reacted into the Message: "+jsonMap.toString());

    int convsIndex = 0;
    for(int i=0; i< conversations.length; i++){
      if(conversations[i].id == jsonMap['convsId']) {
        convsIndex = i;
        break;
      }
    }
    React react = React(title: jsonMap['reactTitle'], userId: jsonMap['newUserId']);
    int messageIndex = 0;
    for(int i =0; i<conversations[convsIndex].messages!.length; i++){
      if(conversations[convsIndex].messages![i].id==jsonMap['messageId']){
        messageIndex = i;
        break;
      }
    }

    if (!conversations[convsIndex]
        .messages![messageIndex]
        .reacts!.contains(react)) {

      conversations[convsIndex]
          .messages![messageIndex]
          .reacts!
          .add(react);
      print("now react data: "+conversations[convsIndex]
          .messages![messageIndex]
          .reacts!.length.toString());

      conversations.refresh();
    }
  }
}
