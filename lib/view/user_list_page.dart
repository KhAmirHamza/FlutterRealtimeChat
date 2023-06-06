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
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.userController.getUsersDataExceptOne(
          widget.currentUser.name, widget.currentUser.email);
    });


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
    List<String> receivedBy = <String>[];
    seenBy.add(widget.currentUser.id.toString());
    receivedBy.add(widget.currentUser.id.toString());

    List<React> reacts = <React>[];

    Message message = Message(
        id: "Initial",
        from: widget.currentUser,
        to: "All",
        text: "Initial",
        seenBy: seenBy,
        receivedBy: receivedBy,
        imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKTSNwcT2YrRQJKGVQHClGtQgp1_x8kLd0Ig&usqp=CAU",
      reacts: reacts,
      replyOf: null);

    widget.users.add(widget.currentUser);
    widget.users.add(widget.selectedUser);

    return Card(
      child: InkWell(
        onTap: (){
          widget.convsController.sendFirstMessage(  context, widget.socket, widget.userController, widget.convsController, widget.currentUser,
              widget.selectedUser, null,  title, message, "Single", );
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomePage(widget.userController, widget.currentUser, widget.socket, widget.convsController)
              ));



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

}
