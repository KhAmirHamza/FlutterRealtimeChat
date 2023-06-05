//import 'dart:io';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import 'package:dio/src/form_data.dart' as FormData;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:realtime_chat/controller/userController.dart';
import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:get/get_connect/http/src/multipart/form_data.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:realtime_chat/view/conversation_list_widget.dart';
import 'package:realtime_chat/view/typing_indicator.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:lottie/lottie.dart';
import 'package:dio/src/multipart_file.dart' as MultipartFile;

import 'package:http/http.dart' as http;

import '../model/Conversation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

bool isChatting = true;
Message? replyMessage;

class pToP_ChatPage extends StatefulWidget implements OnMessageSend {
  // Completely Done for now
  ConversationController convsController;
  User currentUser, selectedUser;
  int convsIndex;
  final dio = Dio();
  IO.Socket socket;
  UserController userController;

  pToP_ChatPage(this.convsController, this.currentUser, this.selectedUser,
      this.socket, this.convsIndex, this.userController,
      {super.key});

  @override
  State<pToP_ChatPage> createState() => _pToP_ChatPageState();

  @override
  void onMessageSend() {
    // TODO: implement onMessageSend
    print("OnMessageSendCalled");

    String notifyMessageSendEvent = "notifyMessageSend?convsType=Single";
    socket.on(notifyMessageSendEvent, (data) {
      Message message = convsController.conversations[convsIndex].messages![
          convsController.conversations[convsIndex].messages!.length - 1];

      //if (!(message.seenBy!.contains(currentUser.id!))) {
      // message.receivedBy!.add(widget.currentUser.id!)
      //  conversations[ convsIndex].messages!.add( message );

      Conversation conversation = convsController.conversations[convsIndex];

      if (isChatting) {
        convsController.seenMessage(conversation.id!, conversation.type!,
            message.id!, socket, currentUser.id!);

        convsController.conversations.refresh();
      }
      //  }
    });
  }
}

class _pToP_ChatPageState extends State<pToP_ChatPage> {
  List<String> typingUsersId = <String>[];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isChatting = true;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    String typingEvent = "typing"; //sending event name...

    if (typingUsersId.contains(widget.currentUser.id)) {
      typingUsersId.remove(widget.currentUser.id);
      var json = {
        "convsId": widget.convsController.conversations[widget.convsIndex].id,
        "convsType":
            widget.convsController.conversations[widget.convsIndex].type,
        "typingUsersId": typingUsersId
      };

      widget.socket.emit(typingEvent, json);
    }

    isChatting = false;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Message message = widget
          .convsController.conversations[widget.convsIndex].messages![widget
              .convsController
              .conversations[widget.convsIndex]
              .messages!
              .length -
          1];

      if (!message.receivedBy!.contains(widget.currentUser.id)) {
        widget
            .convsController
            .conversations[widget.convsIndex]
            .messages![widget.convsController.conversations[widget.convsIndex]
                    .messages!.length -
                1]
            .receivedBy!
            .add(widget.currentUser.id!);

        widget.convsController.receivedMessage(
            widget.convsController.conversations[widget.convsIndex].id!,
            widget.convsController.conversations[widget.convsIndex].type!,
            message.id!,
            widget.socket,
            widget.currentUser.id!);

        //widget.convsController.conversations.refresh();
      }

      if (!message.seenBy!.contains(widget.currentUser.id)) {
        widget
            .convsController
            .conversations[widget.convsIndex]
            .messages![widget.convsController.conversations[widget.convsIndex]
                    .messages!.length -
                1]
            .seenBy!
            .add(widget.currentUser.id!);

        widget.convsController.seenMessage(
            widget.convsController.conversations[widget.convsIndex].id!,
            widget.convsController.conversations[widget.convsIndex].type!,
            message.id!,
            widget.socket,
            widget.currentUser.id!);

        widget.convsController.conversations.refresh();
      }

      String typingEvent =
          "typing?convsId=${widget.convsController.conversations[widget.convsIndex].id}"; //typing event name...
      widget.socket.on(typingEvent, (data) {
        var jsonMap = data as Map<String, dynamic>;
        var result = jsonMap['typingUsersId'].toList();

        List<String> ids = <String>[];
        for (int i = 0; i < result.length; i++) {
          ids.add(result[i]);
        }

        //typingUsersId.clear();

        // if(ids.isNotEmpty && ids[ids.length-1]!=widget.currentUser.id){
        typingUsersId = ids;
        setState(() {
          //  print("Typing: users: "+result.length.toString());
        });
        //  }
      });

      String notifyMessageReceivedEvent =
          "notifyMessageReceived?convsType=Single";
      widget.socket.on(notifyMessageReceivedEvent, (data) {
        widget.convsController.onMessageReceived(widget.socket, data);
      });

      String notifyMessageSeenEvent = "notifyMessageSeen?convsType=Single";
      widget.socket.on(notifyMessageSeenEvent, (data) {
        //
        // var jsonMap = data as Map<String, dynamic>;
        // String newUserId = jsonMap['newUserId'];

        print("isChatting: " + isChatting.toString());
        if (isChatting) {
          widget.convsController.onMessageSeen(widget.socket, data);
        } else {}
        ;
      });
    });

    return WillPopScope(
      onWillPop: () async {
        widget.socket.clearListeners();

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ConversationListWidget(
                    widget.userController,
                    widget.currentUser,
                    widget.socket,
                    widget.convsController)));

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          shadowColor: Colors.white,
          elevation: 1,
          leading: BackButton(
            color: Colors.black,
            onPressed: () {
              //Navigator.of(context, rootNavigator: true).pop();
            widget.socket.clearListeners();

              Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ConversationListWidget(
                      widget.userController,
                      widget.currentUser,
                      widget.socket,
                      widget.convsController)));
            },
          ),
          backgroundColor: Colors.white,
          title: Align(
            alignment: Alignment.center,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    widget.selectedUser.name.toString(),
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 3),
                      child: Text(
                        "Neways Internationl (S&IT)",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      )),
                ]),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.call_outlined,
                color: Colors.black,
              ),
              tooltip: 'Call Now',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('This feature is coming soon!')));
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.more_horiz,
                color: Colors.black,
              ),
              tooltip: 'More',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('This feature is coming soon!')));
              },
            ),
          ],
        ),
        body: MessageListWidget(
            widget.convsController,
            widget.currentUser,
            widget.selectedUser,
            widget.socket,
            widget.convsIndex,
            typingUsersId),
      ),
    );
  }
}

class MessageListWidget extends StatefulWidget {
  ConversationController convsController;
  User currentUser, selectedUser;
  IO.Socket socket;
  int convsIndex;

  List<String> typingUsersId;

  final dio = Dio();

  MessageListWidget(this.convsController, this.currentUser, this.selectedUser,
      this.socket, this.convsIndex, this.typingUsersId,
      {super.key});

  @override
  State<MessageListWidget> createState() => _MessageListWidgetState();
}


class _MessageListWidgetState extends State<MessageListWidget> {

  refreshRepliedMessage(){
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> ids = widget.typingUsersId;

    if (ids.contains(widget.currentUser.id)) ids.remove(widget.currentUser.id);

    return Column(
      children: <Widget>[
        Expanded(child: GetX<ConversationController>(
          builder: (controller) {
            var items = widget
                .convsController.conversations[widget.convsIndex].messages;

            return ListView.builder(
              reverse: true,
              itemCount: items!.length,
              itemBuilder: (context, index) {
                final reversedIndex = items.length - 1 - index;
                final item = items[reversedIndex];

                bool hasSeen = false;
                if (item.seenBy!.contains(widget.selectedUser.id)) {
                  hasSeen = true;
                }
                bool hasReceived = false;
                if (item.receivedBy!.contains(widget.selectedUser.id)) {
                  hasReceived = true;
                }

                print("SeenByNow1: ${item.seenBy}");

                int position =
                    getLastSendMessageIndex(widget.currentUser.id!, items);

                bool isLastSendMessage = reversedIndex == position;

                String createdAtDate =
                    item.createdAt!.toString().substring(0, 10);

                bool hasMessagesAtSameDay = false;
                if (reversedIndex > 0) {
                  String createdAtPreviousDate =
                      items[reversedIndex - 1].createdAt!.substring(0, 10);
                  if (createdAtPreviousDate == createdAtDate)
                    hasMessagesAtSameDay = true;
                }
                return Column(
                  children: [
                    Visibility(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0, 50, 0, 10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: Colors.blueGrey[400],
                              borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
                            child: Text(
                              item.createdAt.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      visible: !hasMessagesAtSameDay,
                    ),
                    ChatBubble(
                        messageIndex: reversedIndex,
                        convsIndex: widget.convsIndex,
                        isCurrentUser: item.from!.id == widget.currentUser.id,
                        hasSeen: hasSeen,
                        hasReceived: hasReceived,
                        isLastSendMessage: isLastSendMessage,
                        convsController: widget.convsController,
                        socket: widget.socket,
                        currentUser: widget.currentUser, refreshRepliedMessage:refreshRepliedMessage,),
                  ],
                );
              },
            );
          },
        )),
        TypingIndicator(
          showIndicator: ids.isNotEmpty,
          bubbleColor: Colors.black12,
          flashingCircleBrightColor: Colors.white,
          flashingCircleDarkColor: Colors.blueAccent,
        ),


        replyMessage==null? Container():
        Visibility(
          visible: replyMessage!=null,
          child: Container(
            margin: EdgeInsets.fromLTRB(10,5,10,0),
            width: double.infinity,
            child: DecoratedBox(

              // chat bubble decoration
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          replyMessage!.from!.name!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w400),
                        ),
                      ), 
                      Expanded(
                        child: Container(
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(onTap: (){
                            replyMessage = null;
                            refreshRepliedMessage();
                          }, child: Icon(Icons.close, size: 20,)),
                        ),
                      )
                    ],),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                      child: (replyMessage!.imageUrl != null &&
                          replyMessage!.imageUrl!.length > 0)
                          ? Image.network(
                          replyMessage!.imageUrl.toString())
                          : Text(
                        replyMessage!.text.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1!
                            .copyWith(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w400),
                      ),
                    ),
                  ],
                )),
          ),
        ),

        ChatMessageTypingField(
            widget.convsController,
            widget.currentUser,
            widget.selectedUser,
            widget.socket,
            widget.convsIndex,
            widget.typingUsersId, refreshRepliedMessage),
      ],
    );
  }
}

int getLastSendMessageIndex(String currentUserId, List<Message> items) {
  int result = 0;
  for (var i = items.length - 1; i >= 0; i--) {
    if (items[i].from!.id == currentUserId) {
      result = i;
      break;
    }
  }
  return result;
}

class ChatBubble extends StatefulWidget {
  ChatBubble({
    Key? key,
    required this.messageIndex,
    required this.convsIndex,
    required this.isCurrentUser,
    required this.hasSeen,
    required this.hasReceived,
    required this.isLastSendMessage,
    required this.convsController,
    required this.socket,
    required this.currentUser,
    required this.refreshRepliedMessage,
  }) : super(key: key);
  final int messageIndex;
  final int convsIndex;
  final bool isCurrentUser;
  final bool hasSeen;
  final bool hasReceived;
  final bool isLastSendMessage;
  final ConversationController convsController;
  final IO.Socket socket;
  final User currentUser;

  Function() refreshRepliedMessage;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  Offset _tapPosition = Offset.zero;

  void _getTapPosition(TapDownDetails tapPosition) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;

    setState(() {
      _tapPosition = referenceBox.globalToLocal(tapPosition.globalPosition);
      print(_tapPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    Message message = widget.convsController.conversations[widget.convsIndex]
        .messages![widget.messageIndex];
    var x, y;

    _onTapDown(TapDownDetails details) {
      x = details.globalPosition.dx;
      y = details.globalPosition.dy;
      // or user the local position method to get the offset
      print(details.localPosition);
      print("tap down " + x.toString() + ", " + y.toString());
    }

    _onTapUp(TapUpDetails details) {
      x = details.globalPosition.dx;
      y = details.globalPosition.dy;
      // or user the local position method to get the offset
      print(details.localPosition);
      print("tap up " + x.toString() + ", " + y.toString());
    }

    void _showPopUpMenuAtPosition(var x, var y, bool isCurrentUser) async {
      final RenderObject? overlay =
          Overlay.of(context).context.findRenderObject();

      final result = await showMenu(
          context: context,
          clipBehavior: Clip.hardEdge,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          color: Colors.transparent,
          position: RelativeRect.fromRect(
              Rect.fromLTWH(x, y-20, 100, 100),
              Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
                  overlay.paintBounds.size.height)),
          items: [
            PopupMenuItem(
              padding: EdgeInsets.symmetric(vertical: 7),
              value: "fav",
              child: AnimatedContainer(
                width: 250,
                padding: EdgeInsets.fromLTRB(5, 35, 5, 25),
                duration: const Duration(milliseconds: 1000),
                // Provide an optional curve to make the animation feel smoother.
                decoration: BoxDecoration(
                  // boxShadow: [BoxShadow(color: Colors.grey)],
                  image: DecorationImage(
                    image: isCurrentUser
                        ? AssetImage('assets/chat_box_right.png')
                        : AssetImage('assets/chat_box_left.png'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                curve: Curves.fastOutSlowIn,

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 10, 0, 0),
                          //  padding: EdgeInsets.all(2),
                          height: 40,
                          width: 40,
                          child: FloatingActionButton(
                              heroTag: 'btn1',
                              tooltip: 'Secret Chat',
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              splashColor: Colors.blue,
                              elevation: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(25)),
                                // padding: EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://www.gifcen.com/wp-content/uploads/2022/05/thumbs-up-gif-7.gif',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                List<React> reacts = widget
                                    .convsController
                                    .conversations[widget.convsIndex]
                                    .messages![widget.messageIndex]
                                    .reacts!;
                                // React r = reacts.firstWhere((it) => it.userId == widget.currentUser.id);
                                if (!reacts.any((item) =>
                                    item.userId == widget.currentUser.id)) {
                                  widget.convsController.addReactUpdateConvs(
                                      widget.convsIndex,
                                      widget.messageIndex,
                                      widget.convsController
                                          .conversations[widget.convsIndex].id!,
                                      widget
                                          .convsController
                                          .conversations[widget.convsIndex]
                                          .type!,
                                      message.id!,
                                      "like",
                                      widget.socket,
                                      widget.currentUser.id!);
                                }
                                Navigator.pop(context);
                              }),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(5, 10, 0, 0),
                          //   padding: EdgeInsets.all(2),
                          height: 40,
                          width: 40,
                          child: FloatingActionButton(
                              heroTag: 'btn1',
                              tooltip: 'Secret Chat',
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              splashColor: Colors.blueAccent,
                              elevation: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25)),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://cdn.pixabay.com/animation/2022/10/28/19/23/19-23-08-315_512.gif',
                                    fit: BoxFit.fitHeight,
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                List<React> reacts = widget
                                    .convsController
                                    .conversations[widget.convsIndex]
                                    .messages![widget.messageIndex]
                                    .reacts!;
                                // React r = reacts.firstWhere((it) => it.userId == widget.currentUser.id);
                                if (!reacts.any((item) =>
                                    item.userId == widget.currentUser.id)) {
                                  widget.convsController.addReactUpdateConvs(
                                      widget.convsIndex,
                                      widget.messageIndex,
                                      widget.convsController
                                          .conversations[widget.convsIndex].id!,
                                      widget
                                          .convsController
                                          .conversations[widget.convsIndex]
                                          .type!,
                                      message.id!,
                                      "Love",
                                      widget.socket,
                                      widget.currentUser.id!);
                                }
                                Navigator.pop(context);
                              }),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(5, 10, 0, 0),
                          height: 40,
                          width: 40,
                          child: FloatingActionButton(
                              heroTag: 'btn1',
                              tooltip: 'Secret Chat',
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              splashColor: Colors.blueAccent,
                              elevation: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25)),
                                // padding: EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://gifdb.com/images/high/cute-finger-heart-hop7csjnvi37i29e.gif',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.fitHeight,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                List<React> reacts = widget
                                    .convsController
                                    .conversations[widget.convsIndex]
                                    .messages![widget.messageIndex]
                                    .reacts!;
                                // React r = reacts.firstWhere((it) => it.userId == widget.currentUser.id);
                                if (!reacts.any((item) =>
                                    item.userId == widget.currentUser.id)) {
                                  widget.convsController.addReactUpdateConvs(
                                      widget.convsIndex,
                                      widget.messageIndex,
                                      widget.convsController
                                          .conversations[widget.convsIndex].id!,
                                      widget
                                          .convsController
                                          .conversations[widget.convsIndex]
                                          .type!,
                                      message.id!,
                                      "Support",
                                      widget.socket,
                                      widget.currentUser.id!);
                                }
                                Navigator.pop(context);
                              }),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(5, 10, 0, 0),
                          height: 40,
                          width: 40,
                          child: FloatingActionButton(
                              heroTag: 'btn1',
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              splashColor: Colors.blueAccent,
                              elevation: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25)),
                                // padding: EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://i.pinimg.com/originals/b8/fe/79/b8fe7956472296b40f3ce7a7e7d68108.gif',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.fitHeight,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                List<React> reacts = widget
                                    .convsController
                                    .conversations[widget.convsIndex]
                                    .messages![widget.messageIndex]
                                    .reacts!;
                                // React r = reacts.firstWhere((it) => it.userId == widget.currentUser.id);
                                if (!reacts.any((item) =>
                                    item.userId == widget.currentUser.id)) {
                                  widget.convsController.addReactUpdateConvs(
                                      widget.convsIndex,
                                      widget.messageIndex,
                                      widget.convsController
                                          .conversations[widget.convsIndex].id!,
                                      widget
                                          .convsController
                                          .conversations[widget.convsIndex]
                                          .type!,
                                      message.id!,
                                      "Hate",
                                      widget.socket,
                                      widget.currentUser.id!);
                                }
                                Navigator.pop(context);
                              }),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 10, 5, 0),
                          height: 40,
                          width: 40,
                          child: FloatingActionButton(
                              heroTag: 'btn1',
                              tooltip: 'Secret Chat',
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              splashColor: Colors.blueAccent,
                              elevation: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25)),
                                // padding: EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://media.tenor.com/l5_u4JytFLYAAAAC/wow-emoji.gif',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.fitHeight,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                List<React> reacts = widget
                                    .convsController
                                    .conversations[widget.convsIndex]
                                    .messages![widget.messageIndex]
                                    .reacts!;
                                // React r = reacts.firstWhere((it) => it.userId == widget.currentUser.id);
                                if (!reacts.any((item) =>
                                    item.userId == widget.currentUser.id)) {
                                  widget.convsController.addReactUpdateConvs(
                                      widget.convsIndex,
                                      widget.messageIndex,
                                      widget.convsController
                                          .conversations[widget.convsIndex].id!,
                                      widget
                                          .convsController
                                          .conversations[widget.convsIndex]
                                          .type!,
                                      message.id!,
                                      "Surprised",
                                      widget.socket,
                                      widget.currentUser.id!);
                                }
                                Navigator.pop(context);
                              }),
                        ),
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Expanded(
                              child: InkWell(
                                onTap: (){
                                  replyMessage = message;
                                  // ReplyOf replyData = ReplyOf(
                                  //     id: replyMessage!.id,
                                  //     from: replyMessage!.from,
                                  //     to: replyMessage!.to,
                                  //     senderName: replyMessage!.from!.name,
                                  //     text: replyMessage!.text, imageUrl: replyMessage!.imageUrl);
                                  // replyMessage!.replyOf = replyData;

                                  /*
                                  Message(id: "abcd", from: widget.currentUser,
                                      to: message.from!.id==widget.currentUser.id? message.to: message.from!.id,
                                  "messageText",*/

                                  //)
                                  //widget.convsController.conversations[widget.convsIndex].messages!.add(replyMessage!);
                                  //widget.convsController.conversations.refresh();

                                  Navigator.pop(context);
                                  widget.refreshRepliedMessage();
                                },
                                child: Column(
                            children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Icon(Icons.message_rounded, size: 20,),
                                ),
                                Text("Reply",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black))
                            ],
                          ),
                              )),
                          Expanded(
                              child: Column(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.forward, size: 20,),
                              ),
                              Text("Forward",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black))
                            ],
                          )),
                          Expanded(
                              child: Column(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.copy, size: 20,),
                              ),
                              Text("Copy",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black))
                            ],
                          )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            /*  PopupMenuItem(
                padding: EdgeInsets.symmetric(vertical: 7),
                value: "fav",
                child: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                    Expanded(child: Column(children: [
                      Align(alignment: Alignment.center, child: Icon(Icons.message_rounded),),
                      Text("Reply", textAlign: TextAlign.center,style: TextStyle(fontSize: 14,color: Colors.black))
                    ],)),
                    Expanded(child: Column(children: [
                      Align(alignment: Alignment.center, child: Icon(Icons.forward),),
                      Text("Forward", textAlign: TextAlign.center,style: TextStyle(fontSize: 14,color: Colors.black))
                    ],)),
                    Expanded(child: Column(children: [
                      Align(alignment: Alignment.center, child: Icon(Icons.copy),),
                      Text("Reply", textAlign: TextAlign.center, style: TextStyle(fontSize: 14,color: Colors.black))
                    ],)),
                  ],
                  ),
                ))*/
          ]);
      // perform action on selected menu item
      switch (result) {
        case 'fav':
          print("fav");
          break;
        case 'close':
          print('close');
          Navigator.pop(context);
          break;
      }
    }

    int like = 0, love = 0, support = 0, surprised = 0, hate = 0;
    int reactCount = message.reacts!.length;

    for (int i = 0; i < reactCount; i++) {
      if (message.reacts![i].title!.toLowerCase() == 'like') {
        like++;
      } else if (message.reacts![i].title!.toLowerCase() == 'love') {
        love++;
      } else if (message.reacts![i].title!.toLowerCase() == 'support') {
        support++;
      } else if (message.reacts![i].title!.toLowerCase() == 'surprised') {
        surprised++;
      } else if (message.reacts![i].title!.toLowerCase() == 'hate') {
        hate++;
      }
    }

    int replyMessagebottomPadding = message.replyOf!=null?5:12;

    return GestureDetector(
        //onTapDown: (position) => {_getTapPosition(position)},
        onTapDown: (TapDownDetails details) => _onTapDown(details),
        onTapUp: (TapUpDetails details) => _onTapUp(details),
        onLongPress: () => {
              //_showContextMenu(context)
              _showPopUpMenuAtPosition(x, y, widget.isCurrentUser)
            },
        onDoubleTap: () => {
              //_showContextMenu(context)
              _showPopUpMenuAtPosition(x, y, widget.isCurrentUser)
            },
        child: Container(
          alignment: widget.isCurrentUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(widget.isCurrentUser ? 64.0 : 16.0, 4,
              widget.isCurrentUser ? 16.0 : 64.0, 4),
          child: Column(
            crossAxisAlignment: widget.isCurrentUser?CrossAxisAlignment.end: CrossAxisAlignment.start,
            children: [
              Visibility(
                visible: message.replyOf!=null,
                child: message.replyOf==null?
                Container():
                Opacity(
                  opacity: .8,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    padding: EdgeInsets.fromLTRB(7,7,7,14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color:  Colors.grey[200],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(0,5,0,5),
                          child: Text(
                            "Replied ${message.replyOf!.from!.name!}'s Messages",
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1!
                                .copyWith(
                                color: Color(Colors.grey[600]!.value),
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w400),

                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                          child: (message.replyOf!.imageUrl != null &&
                              message.replyOf!.imageUrl!.length > 0)
                              ? Image.network(
                              message.replyOf!.imageUrl.toString())
                              : Text(
                            message.replyOf!.text.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1!
                                .copyWith(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IntrinsicWidth(
                stepWidth: 0,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  // crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          widget.isCurrentUser ? 5 : 10, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: widget.isCurrentUser? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [

                        Transform.translate(
                          offset: const Offset(0, -10),
                          child: Row(
                            mainAxisAlignment: widget.isCurrentUser? MainAxisAlignment.end : MainAxisAlignment.start,

                            children: [
                              DecoratedBox(
                                // chat bubble decoration
                                  decoration: BoxDecoration(
                                    color: widget.isCurrentUser
                                        ? Colors.blue[700]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: widget.isCurrentUser? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(12,(message.replyOf!=null)? 7:12, 12,12),
                                          child: (message.imageUrl != null &&
                                              message.imageUrl!.length > 0)
                                              ? Image.network(
                                              message.imageUrl.toString())
                                              : Text(
                                            message.text.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1!
                                                .copyWith(
                                                color: widget.isCurrentUser
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.normal),
                                          ),
                                        ),
                                      ),

                                    ],
                                  ))
                            ],
                          ),
                        ),
                      ],),
                    ),
                    Positioned(
                        bottom: 0,
                        right: 5,
                        child: Row(
                          children: [
                            Visibility(
                              visible: like > 0,
                              child: Container(
                                margin: EdgeInsets.only(right: 1),
                                decoration:
                                    BoxDecoration(shape: BoxShape.circle),
                                // padding: EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://www.gifcen.com/wp-content/uploads/2022/05/thumbs-up-gif-7.gif',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: love > 0,
                              child: Container(
                                margin: EdgeInsets.only(right: 1),
                                decoration:
                                    BoxDecoration(shape: BoxShape.circle),
                                // padding: EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://cdn.pixabay.com/animation/2022/10/28/19/23/19-23-08-315_512.gif',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: surprised > 0,
                              child: Container(
                                margin: EdgeInsets.only(right: 1),
                                decoration:
                                    BoxDecoration(shape: BoxShape.circle),
                                // padding: EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://media.tenor.com/l5_u4JytFLYAAAAC/wow-emoji.gif',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: hate > 0,
                              child: Container(
                                margin: EdgeInsets.only(right: 1),
                                decoration:
                                    BoxDecoration(shape: BoxShape.circle),
                                // padding: EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://i.pinimg.com/originals/b8/fe/79/b8fe7956472296b40f3ce7a7e7d68108.gif',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: support > 0,
                              child: Container(
                                margin: EdgeInsets.only(right: 1),
                                decoration:
                                    BoxDecoration(shape: BoxShape.circle),
                                // padding: EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://gifdb.com/images/high/cute-finger-heart-hop7csjnvi37i29e.gif',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: reactCount > 0,
                              child: Container(
                                margin: EdgeInsets.only(right: 1),
                                decoration:
                                    BoxDecoration(shape: BoxShape.circle,
                                    color: Colors.white,),
                                 padding: EdgeInsets.all(5),
                                child: ClipOval(
                                  child: Text(reactCount.toString(), ),
                                ),
                              ),
                            ),
                          ],
                        ))
                  ],
                ),
              ),
              Visibility(
                visible: widget.isLastSendMessage,
                child: Container(
                  alignment: Alignment.bottomRight,
                  margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: Text(widget.hasSeen
                      ? "Seen"
                      : widget.hasReceived
                          ? "Received"
                          : "Unseen"),
                ),
              ),



            ],
          ),
        ));
  }
}

 sendMessage (
    ConversationController convsController,
    User currentUser,
    String selectedUserId,
    String messageText,
    String imageUrl,
    IO.Socket socket,
    int convsIndex,
     Function() refreshRepliedMessage,
     BuildContext context) async {

  List<String> seenBy = <String>[];
  seenBy.add(currentUser.id.toString());

  List<String> receivedBy = <String>[];
  receivedBy.add(currentUser.id.toString());
  List<React> reacts = <React>[];

  ReplyOf? replyData;

  replyMessage!=null?{
  replyData = ReplyOf(
  id: replyMessage!.id,
  from: replyMessage!.from,
  to: replyMessage!.to,
  senderName: replyMessage!.from!.name,
  text: replyMessage!.text, imageUrl: replyMessage!.imageUrl)
  }: {};


  Message message = Message(
      id: "",
      from: currentUser,
      to: selectedUserId,
      text: messageText,
      seenBy: seenBy,
      receivedBy: receivedBy,
      imageUrl: imageUrl,
      reacts: reacts,
      replyOf: replyData);

  await convsController.sendMessage(convsController.conversations[convsIndex].id!,
      convsController.conversations[convsIndex].type!, message, convsIndex);


  replyMessage = null;
  refreshRepliedMessage();
}

class ChatMessageTypingField extends StatefulWidget {
  ConversationController convsController;
  User currentUser, selectedUser;
  IO.Socket socket;
  int convsIndex;
  List<String> typingUsersId;

  Function() refreshRepliedMessage;



  ChatMessageTypingField(this.convsController, this.currentUser,
      this.selectedUser, this.socket, this.convsIndex, this.typingUsersId, this.refreshRepliedMessage,
      {Key? key})
      : super(key: key);

  @override
  _ChatMessageTypingFieldState createState() => _ChatMessageTypingFieldState();
}

class _ChatMessageTypingFieldState extends State<ChatMessageTypingField> {

  TextEditingController messageController = new TextEditingController();
  bool emojiShowing = false;


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [

          Container(
            margin: EdgeInsets.all(15.0),
            height: 61,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35.0),
                      boxShadow: [
                        BoxShadow(
                            offset: Offset(0, 3),
                            blurRadius: 5,
                            color: Colors.grey)
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                            icon: Icon(
                              Icons.face,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () async {
                              setState(() {
                                emojiShowing = !emojiShowing;
                              });
                            }),
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            decoration: InputDecoration(
                                hintText: "Type Something...",
                                hintStyle: TextStyle(color: Colors.blueAccent),
                                border: InputBorder.none),
                            onChanged: (text) {
                              String typingEvent =
                                  "typing"; //sending event name...

                              if (text.isEmpty) {
                                var json = {
                                  "convsId": widget.convsController
                                      .conversations[widget.convsIndex].id,
                                  "convsType": widget.convsController
                                      .conversations[widget.convsIndex].type,
                                  "typingUsersId": widget.typingUsersId
                                };

                                if (widget.typingUsersId
                                    .contains(widget.currentUser.id)) {
                                  widget.typingUsersId
                                      .remove(widget.currentUser.id);
                                  json = {
                                    "convsId": widget.convsController
                                        .conversations[widget.convsIndex].id,
                                    "convsType": widget.convsController
                                        .conversations[widget.convsIndex].type,
                                    "typingUsersId": widget.typingUsersId
                                  };

                                  widget.socket.emit(typingEvent, json);
                                } else {
                                  widget.socket.emit(typingEvent, json);
                                }
                              } else {
                                var json = {
                                  "convsId": widget.convsController
                                      .conversations[widget.convsIndex].id,
                                  "convsType": widget.convsController
                                      .conversations[widget.convsIndex].type,
                                  "typingUsersId": widget.typingUsersId
                                };

                                if (!widget.typingUsersId
                                    .contains(widget.currentUser.id)) {
                                  widget.typingUsersId
                                      .add(widget.currentUser.id!);

                                  json = {
                                    "convsId": widget.convsController
                                        .conversations[widget.convsIndex].id,
                                    "convsType": widget.convsController
                                        .conversations[widget.convsIndex].type,
                                    "typingUsersId": widget.typingUsersId
                                  };

                                  widget.socket.emit(typingEvent, json);
                                } else {
                                  //widget.socket.emit(typingEvent, json);
                                }
                              }

                              setState(() {});
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.photo, color: Colors.blueAccent),
                          onPressed: () {
                            _openGalleryAndUploadImage(
                                widget.convsController,
                                widget.currentUser,
                                widget.selectedUser.id!,
                                messageController,
                                "",
                                widget.socket,
                                widget.convsIndex, widget.refreshRepliedMessage);
                          },
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.attach_file, color: Colors.blueAccent),
                          onPressed: () {},
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Container(
                  padding: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                      color: Colors.blueAccent, shape: BoxShape.circle),
                  child: InkWell(
                    child: messageController.text.length > 0
                        ? Icon(Icons.send, color: Colors.white)
                        : Icon(Icons.keyboard_voice, color: Colors.white),
                    onTap: () {
                      if (messageController.text.length > 0) {
                        //Send Text Message
                        sendMessage(
                            widget.convsController,
                            widget.currentUser,
                            widget.selectedUser.id!,
                            messageController.text,
                            "",
                            widget.socket,
                            widget.convsIndex, widget.refreshRepliedMessage, context);
                        messageController.text = "";


                        if (widget.typingUsersId
                            .contains(widget.currentUser.id)) {
                          //notifying other user that current user is  not typing...

                          widget.typingUsersId.remove(widget.currentUser.id);
                          String typingEvent = "typing"; //sending event name...

                          var json = {
                            "convsId": widget.convsController
                                .conversations[widget.convsIndex].id,
                            "convsType": widget.convsController
                                .conversations[widget.convsIndex].type,
                            "typingUsersId": widget.typingUsersId
                          };

                          widget.socket.emit(typingEvent, json);
                        }
                      } else {
                        //todo...Send Voice Message...
                      }
                    },
                  ),
                )
              ],
            ),
          ),
          Offstage(
            offstage: !emojiShowing,
            child: SizedBox(
                height: 250,
                child: EmojiPicker(
                  textEditingController: messageController,
                  onEmojiSelected: (category, emoji) => {setState(() {})},
                  config: Config(
                    columns: 7,
                    // Issue: https://github.com/flutter/flutter/issues/28894
                    emojiSizeMax: 32 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.30
                            : 1.0),

                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    gridPadding: EdgeInsets.zero,
                    initCategory: Category.RECENT,
                    bgColor: const Color(0xFFF2F2F2),
                    indicatorColor: Colors.blue,
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.blue,
                    backspaceColor: Colors.blue,
                    skinToneDialogBgColor: Colors.white,
                    skinToneIndicatorColor: Colors.grey,
                    enableSkinTones: true,
                    showRecentsTab: true,
                    recentsLimit: 28,
                    replaceEmojiOnLimitExceed: false,
                    noRecents: const Text(
                      'No Recents',
                      style: TextStyle(fontSize: 20, color: Colors.black26),
                      textAlign: TextAlign.center,
                    ),
                    loadingIndicator: const SizedBox.shrink(),
                    tabIndicatorAnimDuration: kTabScrollDuration,
                    categoryIcons: const CategoryIcons(),
                    buttonMode: ButtonMode.MATERIAL,
                    checkPlatformCompatibility: true,
                  ),
                )),
          ),
        ],
      ),
    );
  }

  var file;
  void _openGalleryAndUploadImage(
      ConversationController convsController,
      User currentUser,
      String selectedUserId,
      TextEditingController messageController,
      imageUrl,
      IO.Socket socket,
      int convsIndex, Function() refreshRepliedMessage) async {
    file = await ImagePicker()
        .pickImage(source: ImageSource.gallery); //pick an image
    //upload file...
    List<int> imageBytes = await file.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    //String base64Image = base64Encode(file.readAsBytesSync());
    String filename = file.path.split('/').last;
    print(filename);

    final dio = Dio();
    try {
      var response = await dio.post(
          "https://nodejsrealtimechat.onrender.com/upload",
          data: {"image": base64Image, "name": filename});
      await sendMessage(convsController, currentUser, selectedUserId,
          messageController.text, response.data['url'], socket, convsIndex, refreshRepliedMessage, context);
    } catch (e) {
      print(e.toString());
    } 
  }
}

abstract class OnMessageSend {
  void onMessageSend();
}
