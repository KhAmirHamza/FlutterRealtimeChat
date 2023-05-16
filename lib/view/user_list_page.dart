import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get/get.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:realtime_chat/controller/userController.dart';
import 'package:realtime_chat/model/Conversation.dart';
import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:realtime_chat/view/conversation_list_page.dart';
import 'package:realtime_chat/view/message_list_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class UserListPage extends StatefulWidget {
  UserController userController;
  ConversationController convsController;
  User currentUser;
  IO.Socket socket;
  UserListPage(
      this.userController, this.convsController, this.currentUser, this.socket,
      {super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  @override
  Widget build(BuildContext context) {
    widget.userController.getUsersDataExceptOne(
        widget.currentUser.name, widget.currentUser.email);

    return MaterialApp(
        title: "Choose Contact",
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Container(child: GetX<UserController>(
          builder: (controller) {
            return ListView.builder(
              itemCount: controller.users.length,
              itemBuilder: (context, index) {
                return UserWidget(
                    widget.userController,
                    widget.convsController,
                    widget.currentUser,
                    widget.userController.users[index],
                    widget.socket);
              },
            );
          },
        )));
  }
}

class UserWidget extends StatefulWidget {
  UserController userController;
  ConversationController convsController;
  User currentUser, selectedUser;
  List<Message> messages = <Message>[];

  List<User> users = <User>[];
  IO.Socket socket;
  UserWidget(this.userController, this.convsController, this.currentUser,
      this.selectedUser, this.socket,
      {super.key});

  @override
  State<UserWidget> createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  @override
  Widget build(BuildContext context) {
    List<String> seenBy = <String>[];
    seenBy.add(widget.currentUser.id.toString());

    widget.messages.add(Message(
        id: "Initial",
        fromId: "Initial",
        toId: "Initial",
        text: "Initial",
        seenBy: seenBy,
        imageUrl: "Initial"));
    widget.users.add(widget.currentUser);
    widget.users.add(widget.selectedUser);

    return Card(
      child: InkWell(
        onTap: () => {
          createConversation(
              widget.convsController,
              widget.users,
              widget.userController,
              widget.currentUser,
              widget.messages,
              widget.socket)
        },
        child: Container(
          margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/conversation.png'),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "${widget.selectedUser.name}",
                        style: TextStyle(fontSize: 15, color: Colors.black),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "${widget.selectedUser.email}",
                        style: TextStyle(fontSize: 10, color: Colors.black87),
                      )
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  createConversation(
      ConversationController convsController,
      List<User> users,
      UserController userController,
      User currentUser,
      List<Message> messages,
      IO.Socket socket) {
    convsController.createConversation(context, socket, userController,
        convsController, currentUser, "", users, messages);
  }
}
