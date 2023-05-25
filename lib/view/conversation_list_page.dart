import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:realtime_chat/controller/userController.dart';
import 'package:realtime_chat/model/Conversation.dart';
import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:realtime_chat/view/create_group.dart';
import 'package:realtime_chat/view/group_chat_widget.dart';
import 'package:realtime_chat/view/message_list_page.dart';
import 'package:realtime_chat/view/user_list_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ConversationListPage extends StatelessWidget {
  ConversationController convsController;
  User currentUser;
  UserController userController;
  IO.Socket socket;

  var activeUsers = [];

  ConversationListPage(
      this.userController, this.convsController, this.currentUser, this.socket,
      {super.key});

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      convsController.getConversationByUserId(currentUser.id!);
    });

    socket.on("leaveUser", (leaveUserChatId) {
      print("leaveUserChatId: " + leaveUserChatId);

      //getConvsIndex(widget.convsController.conversations, currentUserId)

      for (int i = 0; i < convsController.conversations.length; i++) {
        for (int j = 0;
            j < convsController.conversations[i].users!.length;
            j++) {
          if (convsController.conversations[i].users![j].chatId ==
              leaveUserChatId) {
            convsController.conversations[i].users![j].status =
                "Offline";
          }
        }
      }
      //idget.convsController.conversations.refresh();
    });

    socket.on("JoinUser", (JoinUserChatId) {
      print("JoinUserChatId: " + JoinUserChatId);
      for (int i = 0; i < convsController.conversations.length; i++) {
        for (int j = 0;
            j < convsController.conversations[i].users!.length;
            j++) {
          if (convsController.conversations[i].users![j].chatId ==
              JoinUserChatId) {
            convsController.conversations[i].users![j].status = "Online";
          }
        }
      }
      //widget.convsController.conversations.refresh();
    });

    return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();

              }, color: Colors.black),
              title: Align(
                alignment: Alignment.topLeft,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Choose Conversation",
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      Text(
                        "7 Online",
                        style: TextStyle(fontSize: 10),
                      ),
                    ]),
              ),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  tooltip: 'Settings',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('This feature is coming soon!')));
                  },
                ),
              ],
            ),
            body: Container(
              child: Column(
                children: [
                  Expanded(child: GetX<ConversationController>(
                    builder: (controller) {
                      return ListView.builder(
                        itemCount: controller.conversations.length,
                        itemBuilder: (context, index) {
                          return ConversationWidget(
                              convsController,
                              userController,
                              convsController.conversations[index],
                              currentUser,
                              socket,
                              index);
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

                            //pushAndRemoveUntil

                            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
                                builder: (context) => UserListPage(
                                    userController,
                                    convsController,
                                    currentUser,
                                    socket)), (Route<dynamic> route) => false);

                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //       builder: (context) => UserListPage(
                            //           userController,
                            //           convsController,
                            //           currentUser,
                            //           socket)),
                            // );
                          },
                          label: const Text('Add'),
                          icon: const Icon(Icons.message),
                          backgroundColor: Color.fromARGB(255, 19, 149, 88),
                        )),
                  )
                ],

            )));
  }
}

class ConversationWidget extends StatefulWidget {
  ConversationController convsController;
  UserController userController;
  Conversation conversation;
  User currentUser;
  IO.Socket socket;
  int index;

  ConversationWidget(this.convsController, this.userController,
      this.conversation, this.currentUser, this.socket, this.index,
      {super.key});

  @override
  State<ConversationWidget> createState() => _ConversationWidgetState();
}

class _ConversationWidgetState extends State<ConversationWidget> {
  @override
  Widget build(BuildContext context) {
    var otherUserActiveStatus =
        widget.conversation.users![0].id == widget.currentUser.id
            ? widget.conversation.users![1].status
            : widget.conversation.users![0].status;

    String? lastMessage = widget
                .conversation
                .messages![widget.conversation.messages!.length - 1]
                .text!
                .length <
            1
        ? "Photo"
        : widget.conversation
            .messages![widget.conversation.messages!.length - 1].text;

    String? lastMessageTime = widget.conversation
        .messages![widget.conversation.messages!.length - 1].createdAt;
    User selectedUser =
        widget.conversation.users![0].id == widget.currentUser.id
            ? widget.conversation.users![1]
            : widget.conversation.users![0];

    return Card(
      elevation: 8,
      child: InkWell(
        onTap: () => {
          // print("widget.conversation.id:"+widget.convsController.conversations[widget.index].id.toString()),

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => widget.conversation.type=="Group"
                      ? GroupChatWidget(widget.convsController,
                          widget.currentUser, widget.socket, widget.index)
                      : MessageListPage(
                          widget.convsController,
                          widget.currentUser,
                          selectedUser,
                          widget.socket,
                          widget.index)))
        },
        child: Container(
          margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFFF05A22),
                    style: BorderStyle.solid,
                    width: 1.0,
                  ),
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage('assets/conversation.png'),
                  backgroundColor: Colors.black12,
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(15, 5, 10, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "${widget.conversation.title}",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 5),
                      alignment: Alignment.topLeft,
                      child: Text(
                        "$lastMessage",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        lastMessageTime!,
                        style: TextStyle(),
                      ),
                    ),
                    Container(
                      alignment: Alignment.bottomRight,
                      margin: EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                              margin: EdgeInsets.only(right: 5),
                              child: Text(otherUserActiveStatus.toString())),
                          SizedBox(
                            width: 15,
                            height: 15,
                            child: CircleAvatar(
                                backgroundColor:
                                    otherUserActiveStatus != "Online"
                                        ? Colors.black54
                                        : Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showCustomDialog(
      BuildContext context,
      ConversationController convsController,
      UserController userController,
      User currentUser,
      List<Message> messages,
      IO.Socket socket) {
    print("Next Clicked: " + selectedUsers.length.toString());

    TextEditingController groupNameController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            height: 300,
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                          offset: Offset(0, 3),
                          blurRadius: 7,
                          color: Colors.blueGrey)
                    ],
                  ),
                  child: Container(
                    margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Material(
                      child: TextField(
                        controller: groupNameController,
                        decoration: const InputDecoration(
                          hintText: "Name of the group",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onChanged: (text) {
                          //todo.... search user...
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  margin: EdgeInsets.fromLTRB(5, 35, 5, 5),
                  child: Text(
                    "Selected Contact",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                Expanded(
                    child: ListView.builder(
                        itemCount: selectedUsers.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          // return EmployeeItem(selecteUsers, index);
                          return Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Container(
                                margin: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(
                                          "https://cdn-icons-png.flaticon.com/512/2815/2815428.png"),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    Text(
                                      selectedUsers[index].name.toString(),
                                      style: TextStyle(fontSize: 10),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        })),
                Expanded(
                  child: Container(
                    alignment: Alignment.bottomRight,
                    margin: EdgeInsets.all(5),
                    child: MaterialButton(
                      color: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22.0)),
                      clipBehavior: Clip.antiAlias,
                      elevation: 8,
                      onPressed: () {
                        //todo... goto next page
                        print("Submit Clicked!");
                        List<String> seenBy = <String>[];
                        seenBy.add(currentUser.id.toString());

                        messages.add(Message(
                            id: "Initial",
                            fromId: "Initial",
                            toId: "Initial",
                            text: "Initial",
                            seenBy: seenBy,
                            imageUrl:
                                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKTSNwcT2YrRQJKGVQHClGtQgp1_x8kLd0Ig&usqp=CAU"));

                        selectedUsers.add(currentUser);
                        createGroupConversation(
                            context,
                            convsController,
                            groupNameController.text,
                            selectedUsers,
                            userController,
                            currentUser,
                            messages,
                            socket);
                      },
                      child:
                          Text("Submit", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        Tween<Offset> tween;
        if (anim.status == AnimationStatus.reverse) {
          tween = Tween(begin: Offset(-1, 0), end: Offset.zero);
        } else {
          tween = Tween(begin: Offset(1, 0), end: Offset.zero);
        }

        return SlideTransition(
          position: tween.animate(anim),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }
}
