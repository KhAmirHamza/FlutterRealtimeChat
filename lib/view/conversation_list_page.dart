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
import 'package:realtime_chat/view/message_list_page.dart';
import 'package:realtime_chat/view/user_list_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ConversationListPage extends StatefulWidget {
  ConversationController convsController;
  User currentUser;
  UserController userController;
  IO.Socket socket;

  var activeUsers = [];

  ConversationListPage(
      this.userController, this.convsController, this.currentUser, this.socket,
      {super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {


  @override
  Widget build(BuildContext context) {
    widget.convsController.getConversationByUserId(widget.currentUser.id!);
    
    widget.socket.on("leaveUser", (leaveUserChatId){
      print("leaveUserChatId: "+ leaveUserChatId);

      //getConvsIndex(widget.convsController.conversations, currentUserId)

      for(int i =0; i< widget.convsController.conversations.length; i++){
        for(int j = 0; j<widget.convsController.conversations[i].users!.length; j++){
          if(widget.convsController.conversations[i].users![j].chatId==leaveUserChatId){
            widget.convsController.conversations[i].users![j].status = "Offline";
          }
        }
      }

      widget.convsController.conversations.refresh();

    });

    widget.socket.on("JoinUser", (JoinUserChatId){
      print("JoinUserChatId: "+ JoinUserChatId);
      for(int i =0; i< widget.convsController.conversations.length; i++){
        for(int j = 0; j<widget.convsController.conversations[i].users!.length; j++){
          if(widget.convsController.conversations[i].users![j].chatId==JoinUserChatId){
            widget.convsController.conversations[i].users![j].status = "Online";
          }
        }
      }
      widget.convsController.conversations.refresh();
    });




    return MaterialApp(
        title: "Conversation Page",
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Container(
          child: Column(
            children: [
              Container(
                child: Text("List of Conversations"),
              ),
              Expanded(child: GetX<ConversationController>(
                builder: (controller) {
                  return ListView.builder(
                    itemCount: controller.conversations.length,
                    itemBuilder: (context, index) {
                      return ConversationWidget(
                          widget.convsController,
                          widget.convsController.conversations[index],
                          widget.currentUser,
                          widget.socket);
                    },
                  );
                },
              )),
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 10, 15),
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        // Add your onPressed code here!
                        print("Add Conversation Clicked");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserListPage(
                                  widget.userController,
                                  widget.convsController,
                                  widget.currentUser,
                                  widget.socket)),
                        );
                      },
                      label: const Text('Add'),
                      icon: const Icon(Icons.message),
                      backgroundColor: Color.fromARGB(255, 19, 149, 88),
                    )),
              )
            ],
          ),
        ));
  }
}

class ConversationWidget extends StatefulWidget {
  ConversationController convsController;
  Conversation conversation;
  User currentUser;
  IO.Socket socket;

  ConversationWidget(
      this.convsController, this.conversation, this.currentUser, this.socket,
      {super.key});

  @override
  State<ConversationWidget> createState() => _ConversationWidgetState();
}

class _ConversationWidgetState extends State<ConversationWidget> {
  @override
  Widget build(BuildContext context) {
    User selectedUser =
        widget.conversation.users![0].id == widget.currentUser.id
            ? widget.conversation.users![1]
            : widget.conversation.users![0];

    var otherUserActiveStatus = widget.conversation.users![0].id==widget.currentUser.id?
    widget.conversation.users![1].status : widget.conversation.users![0].status;

    return Card(
      child: InkWell(
        onTap: () => {

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MessageListPage(widget.convsController,
                      widget.currentUser, selectedUser, widget.socket)))
        },
        child: Container(
          margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/conversation.png'),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "${selectedUser.name}",
                        style: TextStyle(fontSize: 15, color: Colors.black),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        otherUserActiveStatus.toString(),
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
}
