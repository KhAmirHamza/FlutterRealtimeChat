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
import 'package:realtime_chat/controller/userController.dart';
import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:get/get_connect/http/src/multipart/form_data.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import 'package:dio/src/multipart_file.dart' as MultipartFile;

import 'package:http/http.dart' as http;

import '../model/Conversation.dart';
import 'home_page.dart';

class GroupChatWidget extends StatefulWidget {
  // Completely Done for now
  ConversationController convsController;
  UserController userController;
  User currentUser;
  int convsIndex;
  final dio = Dio();
  IO.Socket socket;

  GroupChatWidget(
      this.convsController, this.currentUser, this.socket, this.convsIndex, this.userController,
      {super.key});

  @override
  State<GroupChatWidget> createState() => _GroupChatWidgetState();
}

class _GroupChatWidgetState extends State<GroupChatWidget> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            shadowColor: Colors.white,
            elevation: 1,
            leading: BackButton(
              color: Colors.black,
            onPressed: ()=> {

              Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HomePage(
                      widget.userController,
                      widget.currentUser,
                      widget.socket,
                      widget.convsController)))
            },
          ),
            backgroundColor:Colors.white,
              title: Container( margin: EdgeInsets.only(bottom: 5),
            child: Text(widget.convsController.conversations[widget.convsIndex].title.toString(),
            style: TextStyle(fontSize: 16, color: Colors.black),),
          ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.call_outlined, color: Colors.black,),
                tooltip: 'Call Now',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('This feature is coming soon!')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.black,),
                tooltip: 'More',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('This feature is coming soon!'))
                  );
                },
              ),

            ],),
          body: GroupMessageListWidget(widget.convsController, widget.currentUser, widget.socket, widget.convsIndex),
        );
  }
}

class GroupMessageListWidget extends StatefulWidget {
  ConversationController convsController;
  User currentUser;
  IO.Socket socket;
  int convsIndex;
  final dio = Dio();

  GroupMessageListWidget(
      this.convsController, this.currentUser, this.socket, this.convsIndex,
      {super.key});

  @override
  State<GroupMessageListWidget> createState() => _GroupMessageListWidgetState();
}

class _GroupMessageListWidgetState extends State<GroupMessageListWidget> {

  @override
  Widget build(BuildContext context) {

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
                List<String>? seenBy = item.seenBy;

                User? sender = widget.convsController.conversations[widget.convsIndex].users![0];
                for(int i = 0; i<widget.convsController.conversations[widget.convsIndex].users!.length; i++){
                  if(widget.convsController.conversations[widget.convsIndex].users![i].id==item.from!.id) {
                    sender = widget.convsController.conversations[widget.convsIndex].users![i];
                    break;
                }
                }

                bool hasSeen = true;
                int position = getLastSendMessageIndex(widget.currentUser.id!, items);
                bool isLastSendMessage = reversedIndex == position;
                String createdAtDate =  item.createdAt!.toString().substring(0, 10);
                bool hasMessagesAtSameDay = false;

                if(reversedIndex>0){
                  String createdAtPreviousDate =  items[reversedIndex-1].createdAt!.substring(0, 10);
                  if(createdAtPreviousDate==createdAtDate) hasMessagesAtSameDay = true;
                }
                return Column(children: [
                  Visibility( child: Container( margin: EdgeInsets.fromLTRB(0, 50, 0, 10),
                    child: DecoratedBox(decoration: BoxDecoration(color: Colors.blueGrey[400], borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
                        child: Text( item.createdAt.toString(), style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  ), visible: !hasMessagesAtSameDay,),


                  item.from!.id == widget.currentUser.id? ChatBubble(
                      item: item,
                      isCurrentUser: true,
                      hasSeen: hasSeen,
                      isLastSendMessage: isLastSendMessage,
                      sender: sender!) : ChatBubble(
                      item: item,
                      isCurrentUser: false,
                      hasSeen: hasSeen,
                      isLastSendMessage: isLastSendMessage,
                  sender: sender!)

                ],);

              },
            );
          },
        )),
        ChatMessageTypingField(widget.convsController, widget.currentUser, widget.socket, widget.convsIndex),
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

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.item,

    required this.isCurrentUser,
    required this.hasSeen,
    required this.isLastSendMessage,
    required this.sender,
  }) : super(key: key);
  final Message item;
  final bool isCurrentUser;
  final bool hasSeen;
  final bool isLastSendMessage;
  final User sender;

  @override
  Widget build(BuildContext context) {
    Message message = item;
    return Padding(
      // add some padding
      padding: EdgeInsets.fromLTRB(isCurrentUser ? 64.0 : 0, 4,isCurrentUser ? 16.0 : 64.0,4,),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: isCurrentUser?0:40,
            width: isCurrentUser?0:40,
            child: CircleAvatar(
              radius: 50.0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(0),
                child: Image.network(
                    "https://cdn.iconscout.com/icon/free/png-256/free-apple-photos-493155.png"),
              ),
            ),
          ),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              Container(
                alignment:
                isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(isCurrentUser ? "You": sender.name.toString(), style: TextStyle(fontSize: 12, color: Colors.grey),),
              ),
              Container(
                // align the child within the container
                margin: EdgeInsets.fromLTRB(5, 5, 0, 5),
                  alignment:
                  isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(children: [
                    DecoratedBox(
                      // chat bubble decoration
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.lightBlueAccent[700] : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(5),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Padding(
                                padding: const EdgeInsets.fromLTRB(5,2.5,5,2.5),
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
                                          : Colors.black87, fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                              ),
                            ],
                          ),
                        )
                    ),
                  ],)

              ),
              Visibility(
                visible: isLastSendMessage&&message.seenBy!.length>1,
                child: Container(
                  alignment: Alignment.bottomRight,
                  margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: Text("Seen (${message.seenBy!.length})",style: TextStyle(fontSize: 12),),
                ),
              )
            ]),
          ),
        ],
      ),
    );
  }
}

sendMessage(
    ConversationController convsController,
    User currentUser,
    String messageText,
    String imageUrl,
    IO.Socket socket,
    int convsIndex) {

  List<String> seenBy = <String>[];
  List<String> receivedBy = <String>[];
  seenBy.add(currentUser.id.toString());
  List<React> reacts = <React>[];
  Message message = Message(
    id: "",
    from: currentUser,
    to: "all",
    text: messageText,
    seenBy: seenBy,
    imageUrl: imageUrl,
    reacts: reacts,
    receivedBy: receivedBy,
    replyOf: null
  );

  convsController.sendMessage(
      convsController.conversations[convsIndex].id!,convsController.conversations[convsIndex].type!, message, convsIndex);

}


class ChatMessageTypingField extends StatefulWidget {
  ConversationController convsController;
  User currentUser;
  IO.Socket socket;
  int convsIndex;

  ChatMessageTypingField(this.convsController, this.currentUser, this.socket, this.convsIndex, { Key? key}) : super(key: key);

  @override
  _ChatMessageTypingFieldState createState() => _ChatMessageTypingFieldState();
}
class _ChatMessageTypingFieldState extends State<ChatMessageTypingField> {

  TextEditingController messageController = new TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Container(
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
                      icon: Icon(Icons.face , color: Colors.blueAccent,), onPressed: () {}),
                  Expanded(
                    child: Material(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                            hintText: "Type Something...",
                            hintStyle: TextStyle( color:     Colors.blueAccent),
                            border: InputBorder.none),
                        onChanged: (text){
                          setState(() {
                          });



                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.photo ,  color: Colors.blueAccent),
                    onPressed: () {

                      _openGalleryAndUploadImage(
                          widget.convsController,
                          widget.currentUser,
                          messageController,
                          "",
                          widget.socket, widget.convsIndex);

                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file ,  color: Colors.blueAccent),
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
              child: messageController.text.length>0? Icon(Icons.send, color: Colors.white) : Icon(Icons.keyboard_voice, color: Colors.white),
              onTap: (){
                if(messageController.text.length>0){
                  //Send Text Message
                  sendMessage(widget.convsController, widget.currentUser, messageController.text, "",  widget.socket, widget.convsIndex);
                  messageController.text = "";
                }else{
                  //todo...Send Voice Message...



                }
              },
            ),
          )
        ],
      ),
    );

  }


  var file;
  void _openGalleryAndUploadImage(
      ConversationController convsController,
      User currentUser,
      TextEditingController messageController,
      imageUrl,
      IO.Socket socket, int convsIndex) async {
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
      await sendMessage(convsController, currentUser, messageController.text, response.data['url'], socket, convsIndex);
    } catch (e) {
      print(e.toString());
    }
  }
}

