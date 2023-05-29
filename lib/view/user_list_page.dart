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
import 'package:realtime_chat/view/home_page.dart';
import 'package:realtime_chat/view/p_to_p_chat_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'create_group.dart';

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
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.userController.getUsersDataExceptOne(
        widget.currentUser.name, widget.currentUser.email);
  }
  @override
  Widget build(BuildContext context) {


    return Scaffold(
            appBar: AppBar(
              title: const Text("Select Contact", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),),
              leading: BackButton(onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              }, color: Colors.black),
            ),
            body: Column(children: <Widget>[

              InkWell(
                onTap: (){
                  print("Create New Group Taped");
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CreateGroupWidget(widget.userController, widget.convsController, widget.currentUser, widget.socket)
                      ));

                },
                splashColor: Colors.pink,
                child: Container(
                padding: EdgeInsets.all(10),
                child: Row(children: [
                  CircleAvatar(backgroundImage: AssetImage('assets/conversation.png'),
                    radius: 20,),
                  Container( margin: EdgeInsets.fromLTRB(5, 10, 0, 10),
                      child: Text("Create new group", style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                ],),
              ),),

              Container(alignment: Alignment.centerLeft, margin: EdgeInsets.fromLTRB(5, 25, 0, 10),
                  child: Text("Neways Users", style: TextStyle(fontSize: 12, color: Colors.grey),)),

              Expanded(
                child: GetX<UserController>(
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
                ),
              )


            ]

        ));
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
    String title = "${widget.currentUser.name} - ${widget.selectedUser.name}";

    List<String> seenBy = <String>[];
    seenBy.add(widget.currentUser.id.toString());

    widget.messages.add(Message(
        id: "Initial",
        from: widget.currentUser,
        to: "All",
        text: "Initial",
        seenBy: seenBy,
        imageUrl:
            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKTSNwcT2YrRQJKGVQHClGtQgp1_x8kLd0Ig&usqp=CAU"));
    widget.users.add(widget.currentUser);
    widget.users.add(widget.selectedUser);

    return Card(
      child: InkWell(
        onTap: () => {

          createSingleConversation(
              widget.convsController,
              title,
              widget.users,
              widget.userController,
              widget.currentUser,
              widget.selectedUser,
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

  createSingleConversation(
      ConversationController convsController,
      String title,
      List<User> users,
      UserController userController,
      User currentUser,
      User selectedUser,
      List<Message> messages,
      IO.Socket socket) {
    convsController.createSingleConversation(context, socket, userController,
        convsController, currentUser, selectedUser, "", title, "Single", users, messages);
  }
}
