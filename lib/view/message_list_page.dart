//import 'dart:io';
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import 'package:dio/src/form_data.dart' as FormData;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:get/get_connect/http/src/multipart/form_data.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import 'package:dio/src/multipart_file.dart' as MultipartFile;

import 'package:http/http.dart' as http;

import '../model/Conversation.dart';

class MessageListPage extends StatefulWidget {
  // Completely Done for now
  ConversationController convsController;
  User currentUser, selectedUser;
  final dio = Dio();
  IO.Socket socket;

  MessageListPage(
      this.convsController, this.currentUser, this.selectedUser, this.socket,
      {super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  @override
  initState() {
    super.initState();

    int conversationIndex = getConvsIndex(
        widget.convsController.conversations, widget.currentUser.id.toString());
    var messageList =
        widget.convsController.conversations[conversationIndex].messages;

    if (!(messageList![messageList.length - 1]
        .seenBy!
        .contains(widget.currentUser.id!))) {
      String convsId =
          widget.convsController.conversations[conversationIndex].id.toString();
      String messageId = widget
          .convsController
          .conversations[conversationIndex]
          .messages![widget.convsController.conversations[conversationIndex]
                  .messages!.length -
              1]
          .id
          .toString();

      widget.convsController.seenMessage(convsId, messageId, widget.socket,
          widget.selectedUser.id!, widget.currentUser.id!);

      widget
          .convsController
          .conversations[conversationIndex]
          .messages![widget.convsController.conversations[conversationIndex]
                  .messages!.length -
              1]
          .seenBy!
          .add(widget.currentUser.id!);
    }
  }

  receiveMessage() {
    int conversationIndex = 0;
    for (int i = 0; i < widget.convsController.conversations.length; i++) {
      if (widget.convsController.conversations[i].users![0].id ==
              widget.currentUser.id ||
          widget.convsController.conversations[i].users![1].id ==
              widget.currentUser.id) {
        conversationIndex = i;
        break;
      }
    }
    String notifyMessageSeenEvent =
        'notifyMessageSeen=${widget.currentUser.id}';

    widget.socket.on(notifyMessageSeenEvent, (data) {
      print("Other User Has Seen Message: ");

      var jsonMap = data as Map<String, dynamic>;

      widget
          .convsController
          .conversations[conversationIndex]
          .messages![widget.convsController.conversations[conversationIndex]
                  .messages!.length -
              1]
          .seenBy!
          .add(jsonMap['otherUserId']);
      widget.convsController.conversations.refresh();
    });

//Receive Message from Server that actually sent by other Client.
    widget.socket.on(widget.currentUser.id.toString(), (data) {
      var jsonMap = data as Map<String, dynamic>;
      var seenByList = jsonMap['seenBy'].toList();

      List<String> seenBy = <String>[];
      for (var i = 0; i < seenByList.length; i++) {
        //Convert And Reasign Existing SeenBy Data...
        seenBy.add(seenByList[i]);
      }

      if (!(seenBy.contains(widget.currentUser.id!))) {
        seenBy.add(widget.currentUser.id!);

        widget.convsController.conversations[conversationIndex].messages!.add(
            Message(
                id: jsonMap['id'],
                fromId: jsonMap['fromId'],
                toId: jsonMap['toId'],
                text: jsonMap['text'],
                seenBy: seenBy,
                imageUrl: jsonMap['imageUrl']));

        String convsId = widget
            .convsController.conversations[conversationIndex].id
            .toString();

        String messageId = widget
            .convsController
            .conversations[conversationIndex]
            .messages![widget.convsController.conversations[conversationIndex]
                    .messages!.length -
                1]
            .id
            .toString();
        widget.convsController.seenMessage(convsId, messageId, widget.socket,
            widget.selectedUser.id!, widget.currentUser.id!);
        print(jsonMap);
      }
    });
  }

  var file;
  void _openGalleryAndUploadImage(
      ConversationController convsController,
      String currentUserId,
      String selectedUserId,
      TextEditingController messageController,
      imageUrl,
      IO.Socket socket) async {
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
          "https://017a-116-68-198-178.ap.ngrok.io/upload",
          data: {"image": base64Image, "name": filename});
      await sendMessage(convsController, currentUserId, selectedUserId,
          messageController.text, response.data['url'], socket);
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController messageController = TextEditingController();
    int conversationIndex = 0;
    for (int i = 0; i < widget.convsController.conversations.length; i++) {
      if (widget.convsController.conversations[i].users![0].id ==
              widget.currentUser.id ||
          widget.convsController.conversations[i].users![1].id ==
              widget.currentUser.id) {
        conversationIndex = i;
        break;
      }
    }
//Check if last message has not seen yet...
    receiveMessage();
    return Material(
      child: Column(
        children: <Widget>[
          Expanded(child: GetX<ConversationController>(
            builder: (controller) {
              int conversationIndex = 0;
              for (int i = 0;
                  i < widget.convsController.conversations.length;
                  i++) {
                if (widget.convsController.conversations[i].users![0].id ==
                        widget.currentUser.id ||
                    widget.convsController.conversations[i].users![1].id ==
                        widget.currentUser.id) {
                  conversationIndex = i;
                  break;
                }
              }
              var items = widget
                  .convsController.conversations[conversationIndex].messages;

              return ListView.builder(
                reverse: true,
                itemCount: items!.length,
                itemBuilder: (context, index) {
                  final reversedIndex = items.length - 1 - index;
                  final item = items[reversedIndex];
                  List<String>? seenBy = item.seenBy;

                  bool hasSeen = false;
                  if (item.seenBy!.contains(widget.selectedUser.id)) {
                    hasSeen = true;
                  }

                  print("SeenByNow1: " + item.seenBy.toString());

                  int position =
                      getLastSendMessageIndex(widget.currentUser.id!, items);

                  bool isLastSendMessage = reversedIndex == position;
                  if (item.fromId == widget.currentUser.id) {
                    return ChatBubble(
                        message: item,
                        isCurrentUser: true,
                        hasSeen: hasSeen,
                        isLastSendMessage: isLastSendMessage);
                  } else {
                    return ChatBubble(
                        message: item,
                        isCurrentUser: false,
                        hasSeen: hasSeen,
                        isLastSendMessage: isLastSendMessage);
                  }
                },
              );
            },
          )),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () {
                      _openGalleryAndUploadImage(
                          widget.convsController,
                          widget.currentUser.id!,
                          widget.selectedUser.id!,
                          messageController,
                          "",
                          widget.socket);
                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        "+",
                        style: TextStyle(
                          fontSize: 25,
                        ),
                      ),
                    ),
                  )),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type your message',
                    ),
                  ),
                ),
              ),
              Expanded(
                  flex: 1,
                  child: SendMessageButton(
                      widget.convsController,
                      messageController,
                      widget.currentUser.id!,
                      widget.selectedUser,
                      widget.socket,
                      "")),
            ],
          )
        ],
      ),
    );
  }
}

int getLastSendMessageIndex(String currentUserId, var items) {
  int result = 0;
  for (var i = items.length - 1; i >= 0; i--) {
    if (items[i].fromId == currentUserId) {
      result = i;
      break;
    }
  }
  return result;
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    required this.hasSeen,
    required this.isLastSendMessage,
  }) : super(key: key);
  final Message message;
  final bool isCurrentUser;
  final bool hasSeen;
  final bool isLastSendMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // add some padding
      padding: EdgeInsets.fromLTRB(
        isCurrentUser ? 64.0 : 16.0,
        4,
        isCurrentUser ? 16.0 : 64.0,
        4,
      ),
      child: Column(children: [
        Align(
          // align the child within the container
          alignment:
              isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: DecoratedBox(
              // chat bubble decoration
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: (message.imageUrl != null &&
                            message.imageUrl!.length > 0)
                        ? Image.network(message.imageUrl.toString())
                        : Text(
                            message.text.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1!
                                .copyWith(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Colors.black87),
                          ),
                  ),
                ],
              )),
        ),
        Visibility(
          visible: isLastSendMessage,
          child: Container(
            alignment: Alignment.bottomRight,
            margin: EdgeInsets.fromLTRB(0, 5, 10, 0),
            child: Text(hasSeen ? "Seen" : "Unseen"),
          ),
        )
      ]),
    );
  }
}

class SendMessageButton extends StatelessWidget {
  TextEditingController messageController;
  ConversationController convsController;
  String currentUserId;
  User selectedUser;
  IO.Socket socket;
  String imageUrl;

  SendMessageButton(this.convsController, this.messageController,
      this.currentUserId, this.selectedUser, this.socket, this.imageUrl,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          "Send",
          style: TextStyle(fontSize: 25),
        ),
      ),
      onTap: () => {
        sendMessage(convsController, currentUserId, selectedUser.id!,
            messageController.text, imageUrl, socket),
        messageController.text = "",
      },
    );
  }
}

sendMessage(
    ConversationController convsController,
    String currentUserId,
    String selectedUserId,
    String messageText,
    String imageUrl,
    IO.Socket socket) {
  int conversationIndex = 0;
  for (int i = 0; i < convsController.conversations.length; i++) {
    if (convsController.conversations[i].users![0].id == currentUserId ||
        convsController.conversations[i].users![1].id == currentUserId) {
      conversationIndex = i;
      break;
    }
  }

  List<String> seenBy = <String>[];
  seenBy.add(currentUserId);

  Message message = Message(
      id: "",
      fromId: currentUserId,
      toId: selectedUserId,
      text: messageText,
      seenBy: seenBy,
      imageUrl: imageUrl);

  convsController.sendMessage(
      convsController.conversations[conversationIndex].id!, message, socket);
  convsController.conversations[conversationIndex].messages!.add(message);
  convsController.conversations.refresh();
}

int getConvsIndex(List<Conversation> conversations, String currentUserId) {
  int conversationIndex = 0;
  for (int i = 0; i < conversations.length; i++) {
    if (conversations[i].users![0].id == currentUserId ||
        conversations[i].users![1].id == currentUserId) {
      conversationIndex = i;
      break;
    }
  }
  return conversationIndex;
}
