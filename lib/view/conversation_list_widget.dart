import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:realtime_chat/view/user_list_page.dart';

import '../controller/ConvsCntlr.dart';
import '../controller/userController.dart';
import '../model/Conversation.dart';
import '../model/Message.dart';
import '../model/User.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'create_group.dart';
import 'group_chat_widget.dart';
import 'p_to_p_chat_page.dart';


var selectedUsers = <User>[];

class ConversationListWidget extends StatefulWidget {

  User currentUser;
  UserController userController;
  IO.Socket socket;
  ConversationController convsController;

  ConversationListWidget(this.userController, this.currentUser, this.socket, this.convsController, {Key? key}) : super(key: key);

  @override
  State<ConversationListWidget> createState() => _ConversationListWidgetState();
}

class _ConversationListWidgetState extends State<ConversationListWidget> {

  late FocusNode myFocusNode;

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();

  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    myFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {





    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {


      widget.convsController.getConversationByUserId(widget.currentUser.id!);

      widget.socket.on("leaveUser", (leaveUserChatId) {
        print("leaveUserChatId: " + leaveUserChatId);

        //getConvsIndex(widget.convsController.conversations, currentUserId)

        for (int i = 0; i < widget.convsController.conversations.length; i++) {
          for (int j = 0; j < widget.convsController.conversations[i].users!.length; j++) {
            if (widget.convsController.conversations[i].users![j].chatId == leaveUserChatId) { // if leave user, then update status to Offline
              widget.convsController.conversations[i].users![j].status =
              "Offline";
            }
          }
        }
        widget.convsController.conversations.refresh();
      });

      widget.socket.on("JoinUser", (JoinUserChatId) {
        print("JoinUserChatId: " + JoinUserChatId);
        for (int i = 0; i < widget.convsController.conversations.length; i++) {
          for (int j = 0;
          j < widget.convsController.conversations[i].users!.length;
          j++) {
            if (widget.convsController.conversations[i].users![j].chatId == JoinUserChatId) {  // if new user join, then update status to online...
              widget.convsController.conversations[i].users![j].status = "Online";
            }
          }
        }
        widget.convsController.conversations.refresh();
      });





      //String receiveMessageEvent = "receiveMessage?convsId=${convs.id}&convsType=Single";
      String receiveMessageEvent = "receiveMessage?convsType=Single";

      widget.socket.on(receiveMessageEvent, (data) {
        print("Receive Message Called");


        var jsonMap = data as Map<String, dynamic>;
        User user = User.fromJson(jsonMap['from']);

        print("jsonMap");
        print(jsonMap);
        print("user.name");
        print(user.name);
        print(" currentUser.id!");
        print( widget.currentUser.id!);

        if (user.id!=  widget.currentUser.id!) {

          var seenByList = jsonMap['seenBy'].toList();

          List<String> seenBy = <String>[];
          for (var i = 0; i < seenByList.length; i++) {
            //Convert And Reasign Existing SeenBy Data...
            seenBy.add(seenByList[i]);
          }

          print(" currentUser.id:${ widget.currentUser.id}");
          print("seenBy.length pre:${seenBy.length}");


          int convsIndex = 0;
          for(int i=0; i< widget.convsController.conversations.length; i++){
            if(widget.convsController.conversations[i].id == jsonMap['convsId']) {
              convsIndex = i;
              break;
            }
          }

          if (!(seenBy.contains( widget.currentUser.id!))) {
            seenBy.add( widget.currentUser.id!);
            print("seenBy.length post:${seenBy.length}");

            widget.convsController.conversations[ convsIndex].messages!.add(
                Message(
                    id: jsonMap['id'],
                    from: User.fromJson(jsonMap['from']),
                    to: jsonMap['to'],
                    text: jsonMap['text'],
                    seenBy: seenBy,
                    imageUrl: jsonMap['imageUrl'],
                    createdAt: jsonMap['createdAt'],
                    updatedAt: jsonMap['updatedAt']));

          /*  String convsId = convsController.conversations[ convsIndex].id
                .toString();
            String convsType = convsController.conversations[ convsIndex].type
                .toString();

            String messageId = convsController
                .conversations[ convsIndex]
                .messages![ convsController.conversations[ convsIndex]
                .messages!.length -
                1]
                .id
                .toString();*/
             widget.convsController.seenMessage(
                 jsonMap['convsId'], jsonMap['convsType'], jsonMap['id'],  widget.socket,
                 widget.currentUser.id!);
            print(jsonMap);

            widget.convsController.conversations.refresh();

          }
        }
      });

        // String notifyMessageSeenEvent ="notifyMessageSeen?convsId=${widget.convsController.conversations[widget.convsIndex].id}&convsType=Group";
         String notifyMessageSeenEvent ="notifyMessageSeen?convsType=Single";

        widget.socket.on(notifyMessageSeenEvent, (data)
        {
          var jsonMap = data as Map<String, dynamic>;
          print("Other User Has Seen Message: "+jsonMap.toString());

          int convsIndex = 0;
          for(int i=0; i< widget.convsController.conversations.length; i++){
            if(widget.convsController.conversations[i].id == jsonMap['convsId']) {
              convsIndex = i;
              break;
            }
          }

          if (!widget
              .convsController
              .conversations[convsIndex]
              .messages![widget.convsController.conversations[convsIndex]
              .messages!.length -
              1]
              .seenBy!.contains(jsonMap['newUserId'])) {


          widget
              .convsController
              .conversations[convsIndex]
              .messages![widget.convsController.conversations[convsIndex]
              .messages!.length -
              1]
              .seenBy!
              .add(jsonMap['newUserId']);
          widget.convsController.conversations.refresh();

        }
        });
    });

    TextEditingController searchContactController = TextEditingController();




    return Scaffold(
      appBar: AppBar(
      backgroundColor: Colors.white,
      systemOverlayStyle: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white, // Navigation bar
        statusBarColor: Colors.white, // Status bar
      ),
      leading:CircleAvatar(
        radius: 10.0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(10),
          child: Image.network(
              "https://cdn.iconscout.com/icon/free/png-256/free-apple-photos-493155.png"),
        ),
      ),
      shadowColor: Colors.transparent,
      toolbarHeight: 50,

      actions: <Widget>[

        FloatingActionButton(
            heroTag: 'btn1',
            tooltip:
            'Secret Chat',backgroundColor: Colors.white, foregroundColor: Colors.white ,splashColor: Colors.blueAccent,elevation: 0,
            child: Icon(Icons.mail_lock_outlined, color: Colors.black,),
            onPressed: (){

            }),
        FloatingActionButton(
            heroTag: 'btn2',
            tooltip: ''
            'Calender',backgroundColor: Colors.white, foregroundColor: Colors.white ,splashColor: Colors.blueAccent,elevation: 0,
            child: Icon(Icons.calendar_month, color: Colors.black,),
            onPressed: (){

            }),
        FloatingActionButton(
          heroTag: 'btn3',
            tooltip:
            'Add', backgroundColor: Colors.white, foregroundColor: Colors.white ,splashColor: Colors.blueAccent,elevation: 0,
            child: PopupMenuButton(
              // add icon, by default "3 dot" icon
              // icon: Icon(Icons.book)
              icon: Icon(Icons.add, color: Colors.black,),
                itemBuilder: (context){
                  return [
                    PopupMenuItem<int>(
                      value: 0,
                      child: Row(children: [ Icon(Icons.qr_code_sharp,color: Colors.black,), Container(margin: EdgeInsets.only(left: 15), child: Text("Scan QR Code"),)],),
                    ),

                    PopupMenuItem<int>(
                      value: 1,
                      child: Row(children: [ Icon(Icons.message_outlined,color: Colors.black,), Container(margin: EdgeInsets.only(left: 15), child: Text("New Chat"),)],),
                    ),

                    PopupMenuItem<int>(
                      value: 2,
                      child: Row(children: [ Icon(Icons.perm_contact_cal_outlined,color: Colors.black,), Container(margin: EdgeInsets.only(left: 15), child: Text("Add Contact"),)],),
                    ),
                  ];
                },
                onSelected:(value){
                  if(value == 0){
                    print("Scan QR Code menu is selected.");
                  }else if(value == 1){
                    print("New Chat menu is selected.");

                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => CreateGroupWidget(
                                widget.userController,
                                widget.convsController,
                                widget.currentUser,
                                widget.socket)),
                            (Route<dynamic> route) => true);


                  }else if(value == 2){
                    print("Add Contact menu is selected.");

                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => UserListPage(
                                widget.userController,
                                widget.convsController,
                                widget.currentUser,
                                widget.socket)),
                            (Route<dynamic> route) => true);
                  }
                }
            ),

            onPressed: (){
            }),

      ],
    ),
      body: Container(
        color: Colors.white,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(10, 5, 10, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                        offset: Offset(0, 3),
                        blurRadius: 25,
                        blurStyle: BlurStyle.inner,
                        color: Colors.blueGrey)
                  ],
                ),
                child: Container(
                  height: 30,
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Material(
                    child: TextField(
                      focusNode: myFocusNode,
                      controller: searchContactController,
                      decoration: const InputDecoration(
                        hintText: "Search",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
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
                margin: EdgeInsets.only(left: 10),
                child: Row(

                  children: [
                    IconButton(onPressed: (){}, icon: Icon(Icons.flash_on_outlined, color: Colors.blue, size: 17)),
                    IconButton(onPressed: (){}, icon: Icon(Icons.alternate_email_outlined, color: Colors.grey, size: 17,)),
                    IconButton(onPressed: (){}, icon: Icon(Icons.star_border_outlined, color: Colors.grey, size: 17,)),
                    IconButton(onPressed: (){}, icon: Icon(Icons.watch_later_outlined, color: Colors.grey, size: 17,)),
                    IconButton(onPressed: (){}, icon: Icon(Icons.file_copy_outlined, color: Colors.grey, size: 17,)),
                  ],
                ),
              ),

              Expanded(child: GetX<ConversationController>(
                builder: (controller) {
                  return ListView.builder(
                    itemCount: controller.conversations.length,
                    itemBuilder: (context, index) {
                      return
                        ConversationItemWidget(
                          widget.convsController,
                          widget.userController,
                          widget.convsController.conversations[index],
                          widget.currentUser,
                          widget.socket,
                          index);
                    },
                  );
                },
              )),
              // Container(
              //   margin: EdgeInsets.fromLTRB(0, 0, 10, 15),
              //   child: Align(
              //       alignment: Alignment.bottomRight,
              //       child: FloatingActionButton.extended(
              //         onPressed: () {
              //           // Add your onPressed code here!
              //           print("Add Conversation Clicked");
              //
              //           //pushAndRemoveUntil
              //
              //
              //
              //           // Navigator.push(
              //           //   context,
              //           //   MaterialPageRoute(
              //           //       builder: (context) => UserListPage(
              //           //           userController,
              //           //           convsController,
              //           //           currentUser,
              //           //           socket)),
              //           // );
              //         },
              //         label: const Text('Add'),
              //         icon: const Icon(Icons.message),
              //         backgroundColor: Color.fromARGB(255, 19, 149, 88),
              //       )),
              // )
            ],
          )),

    );
  }
}


class ConversationItemWidget extends StatefulWidget {
  ConversationController convsController;
  UserController userController;
  Conversation conversation;
  User currentUser;
  IO.Socket socket;
  int index;

  ConversationItemWidget(this.convsController, this.userController,
      this.conversation, this.currentUser, this.socket, this.index,
      {super.key});

  @override
  State<ConversationItemWidget> createState() => _ConversationItemWidgetState();
}

class _ConversationItemWidgetState extends State<ConversationItemWidget> {

  @override
  Widget build(BuildContext context) {
    var otherUserActiveStatus =
    widget.conversation.users![0].id == widget.currentUser.id
        ? widget.conversation.users![1].status
        : widget.conversation.users![0].status;

    Message message = widget.conversation
        .messages![widget.conversation.messages!.length - 1];

    String? lastMessage = message.text!.isEmpty
        ? "Photo"
        : widget.conversation
        .messages![widget.conversation.messages!.length - 1].text;

    String? lastMessageTime = message.createdAt;

    User selectedUser = widget.conversation.users![0].id == widget.currentUser.id
        ? widget.conversation.users![1]
        : widget.conversation.users![0];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),

      child: Card(
        elevation: 2,

        child: InkWell(
          onTap: () => {
             print("widget.conversation.id:"+widget.convsController.conversations[widget.index].id.toString()),

            Navigator.push(
                context,
                MaterialPageRoute(

                    builder: (context) => widget.conversation.type == "Group"
                        ? GroupChatWidget(widget.convsController,
                        widget.currentUser, widget.socket, widget.index)
                        : pToP_ChatPage(
                        widget.convsController,
                        widget.currentUser,
                        selectedUser,
                        widget.socket,
                        widget.index)

                ))
          },
          child: Container(
            margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blueAccent,
                      style: BorderStyle.solid,
                      width: 1.0,
                    ),
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/conversation.png'),
                    backgroundColor: Colors.black12,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(15, 5, 10, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "${widget.conversation.title}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        alignment: Alignment.topLeft,
                        child: Text("${message.from!.name}: $lastMessage",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
                          style: TextStyle(fontSize: 10, color: Colors.grey),
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
                                child: Text(otherUserActiveStatus.toString(), style: TextStyle(
                                  color: otherUserActiveStatus != "Online"
                                      ? Colors.grey
                                      : Colors.green,
                                  fontSize: 10
                                ),)),

                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircleAvatar(
                                  backgroundColor:
                                  otherUserActiveStatus != "Online"
                                      ? Colors.grey
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
                            from: User(),
                            to: "Initial",
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








