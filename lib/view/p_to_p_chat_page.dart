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

import 'package:dio/src/multipart_file.dart' as MultipartFile;

import 'package:http/http.dart' as http;

import '../model/Conversation.dart';


bool isChatting = true;


class pToP_ChatPage extends StatefulWidget  implements OnMessageSend{
  // Completely Done for now
  ConversationController convsController;
  User currentUser, selectedUser;
  int convsIndex;
  final dio = Dio();
  IO.Socket socket;
  UserController userController;


  pToP_ChatPage(
      this.convsController, this.currentUser, this.selectedUser, this.socket, this.convsIndex, this.userController,
      {super.key});



  @override
  State<pToP_ChatPage> createState() => _pToP_ChatPageState();

  @override
  void onMessageSend() {
    // TODO: implement onMessageSend
    print("OnMessageSendCalled");

    String notifyMessageSendEvent = "notifyMessageSend?convsType=Single";
    socket.on(notifyMessageSendEvent, (data) {
      Message message = convsController
          .conversations[convsIndex]
          .messages![convsController.conversations[convsIndex]
          .messages!.length -
          1];

      //if (!(message.seenBy!.contains(currentUser.id!))) {
        // message.receivedBy!.add(widget.currentUser.id!)
        //  conversations[ convsIndex].messages!.add( message );

        Conversation conversation = convsController.conversations[convsIndex];

        if(isChatting){
          convsController.seenMessage(
              convsController.conversations[convsIndex].id!,
              convsController.conversations[convsIndex].type!,
              conversation.messages![conversation.messages!.length-1].id!,
              socket, currentUser.id!);

         // convsController.conversations.refresh();
        }
    //  }
    });
  }
}

class _pToP_ChatPageState extends State<pToP_ChatPage>{

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

    if(typingUsersId.contains(widget.currentUser.id)){
      typingUsersId.remove(widget.currentUser.id);
      var json = {
        "convsId": widget.convsController.conversations[widget.convsIndex].id,
        "convsType": widget.convsController.conversations[widget.convsIndex].type,
        "typingUsersId": typingUsersId};

      widget.socket.emit(typingEvent, json);
    }

    isChatting = false;
  }



  @override
  Widget build(BuildContext context) {



    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {

      Message message = widget
          .convsController
          .conversations[widget.convsIndex]
          .messages![widget.convsController.conversations[widget.convsIndex]
          .messages!.length -
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
            widget.currentUser.id! );


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




      String typingEvent = "typing?convsId=${widget.convsController.conversations[widget.convsIndex].id}"; //typing event name...
      widget.socket.on(typingEvent, (data){

          var jsonMap = data as Map<String, dynamic>;
          var result = jsonMap['typingUsersId'].toList();

          List<String> ids = <String>[];
          for(int i=0; i<result.length; i++){ ids.add(result[i]);}

          //typingUsersId.clear();

         // if(ids.isNotEmpty && ids[ids.length-1]!=widget.currentUser.id){
          typingUsersId = ids;
            setState(() {

            //  print("Typing: users: "+result.length.toString());
            });
        //  }
      });


      String notifyMessageReceivedEvent ="notifyMessageReceived?convsType=Single";
      widget.socket.on(notifyMessageReceivedEvent, (data){
        widget.convsController.onMessageReceived(widget.socket, data);
      });



      String notifyMessageSeenEvent ="notifyMessageSeen?convsType=Single";
      widget.socket.on(notifyMessageSeenEvent, (data){
        //
        // var jsonMap = data as Map<String, dynamic>;
        // String newUserId = jsonMap['newUserId'];

        print("isChatting: "+isChatting.toString());
        if(isChatting){
          widget.convsController.onMessageSeen(widget.socket, data);

        }else {};
      });

    });


    return WillPopScope(
      onWillPop: () async {
        widget.socket.clearListeners();

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ConversationListWidget(widget.userController, widget.currentUser, widget.socket, widget.convsController)
            ));

      return false;
      },
      child: Scaffold(
        appBar: AppBar(
              shadowColor: Colors.white,
              elevation: 1,
              leading: BackButton(
                color: Colors.black,
              onPressed: ()=> Navigator.of(context, rootNavigator: true).pop(),
            ),

              backgroundColor:Colors.white,

              title: Align( alignment: Alignment.center,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                Text(widget.selectedUser.name.toString(), style: TextStyle(fontSize: 16, color: Colors.black),),
                Container(margin: EdgeInsets.only(top: 3) ,child: Text("Neways Internationl (S&IT)", style: TextStyle(fontSize: 10, color: Colors.grey),)),
              ]),
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
            body: MessageListWidget(widget.convsController, widget.currentUser,
                widget.selectedUser, widget.socket, widget.convsIndex, typingUsersId),
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

  MessageListWidget(
      this.convsController, this.currentUser, this.selectedUser, this.socket, this.convsIndex, this.typingUsersId,
      {super.key});

  @override
  State<MessageListWidget> createState() => _MessageListWidgetState();
}

class _MessageListWidgetState extends State<MessageListWidget> {




  @override
  Widget build(BuildContext context) {

    List<String>  ids = widget.typingUsersId;

    if(ids.contains(widget.currentUser.id)) ids.remove(widget.currentUser.id);


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
                      hasReceived: hasReceived,
                      isLastSendMessage: isLastSendMessage) : ChatBubble(
                      item: item,
                      isCurrentUser: false,
                      hasSeen: hasSeen,
                      hasReceived: hasReceived,
                      isLastSendMessage: isLastSendMessage)

                ],);


              },
            );
          },
        )),

        TypingIndicator(showIndicator: ids.isNotEmpty, bubbleColor: Colors.black12,flashingCircleBrightColor: Colors.white, flashingCircleDarkColor: Colors.blueAccent,),
        ChatMessageTypingField(widget.convsController, widget.currentUser, widget.selectedUser, widget.socket, widget.convsIndex, widget.typingUsersId),

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
    required this.hasReceived,
    required this.isLastSendMessage,
  }) : super(key: key);
  final Message item;
  final bool isCurrentUser;
  final bool hasSeen;
  final bool hasReceived;
  final bool isLastSendMessage;

  @override
  Widget build(BuildContext context) {


    Message message = item;


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
            child: Column(children: [

              DecoratedBox(
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
            ],)

        ),
        Visibility(
          visible: isLastSendMessage,
          child: Container(
            alignment: Alignment.bottomRight,
            margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
            child: Text(hasSeen ? "Seen" : hasReceived? "Received" : "Unseen"),
          ),
        )
      ]),
    );
  }
}

sendMessage(
    ConversationController convsController,
    User currentUser,
    String selectedUserId,
    String messageText,
    String imageUrl,
    IO.Socket socket, int convsIndex) {

  List<String> seenBy = <String>[];
  seenBy.add(currentUser.id.toString());

  List<String> receivedBy = <String>[];
  receivedBy.add(currentUser.id.toString());

  Message message = Message(
      id: "",
      from: currentUser,
      to: selectedUserId,
      text: messageText,
      seenBy: seenBy,
      receivedBy: receivedBy,
      imageUrl: imageUrl,
  );

  convsController.sendMessage(
      convsController.conversations[convsIndex].id!, convsController.conversations[convsIndex].type!, message, convsIndex);


}

class ChatMessageTypingField extends StatefulWidget {
  ConversationController convsController;
  User currentUser, selectedUser;
  IO.Socket socket;
  int convsIndex;
  List<String> typingUsersId;

  ChatMessageTypingField(this.convsController, this.currentUser, this.selectedUser, this.socket, this.convsIndex,  this.typingUsersId, { Key? key}) : super(key: key);

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
                            icon: Icon(Icons.face , color: Colors.blueAccent,), onPressed: () async {

                          setState(() {
                            emojiShowing = !emojiShowing;
                          });



                        }),
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            decoration: InputDecoration(
                                hintText: "Type Something...",
                                hintStyle: TextStyle( color:     Colors.blueAccent),
                                border: InputBorder.none),
                            onChanged: (text){




                              String typingEvent = "typing"; //sending event name...




                              if(text.isEmpty){

                                var json = {
                                  "convsId": widget.convsController.conversations[widget.convsIndex].id,
                                  "convsType": widget.convsController.conversations[widget.convsIndex].type,
                                  "typingUsersId": widget.typingUsersId};

                                if(widget.typingUsersId.contains(widget.currentUser.id)){
                                  widget.typingUsersId.remove(widget.currentUser.id);
                                  json = {
                                  "convsId": widget.convsController.conversations[widget.convsIndex].id,
                                  "convsType": widget.convsController.conversations[widget.convsIndex].type,
                                  "typingUsersId": widget.typingUsersId};

                                  widget.socket.emit(typingEvent, json);
                                }else{
                                  widget.socket.emit(typingEvent, json);
                                }

                              }else {

                                var json = {
                                  "convsId": widget.convsController.conversations[widget.convsIndex].id,
                                  "convsType": widget.convsController.conversations[widget.convsIndex].type,
                                  "typingUsersId": widget.typingUsersId};

                                if (!widget.typingUsersId.contains( widget.currentUser.id)){

                                  widget.typingUsersId.add(widget.currentUser.id!);

                                 json = {
                                  "convsId": widget.convsController.conversations[widget.convsIndex].id,
                                  "convsType": widget.convsController.conversations[widget.convsIndex].type,
                                  "typingUsersId": widget.typingUsersId};

                                widget.socket.emit(typingEvent, json);
                                }else {
                                  //widget.socket.emit(typingEvent, json);
                                }

                              }

                              setState(() {
                              });

                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.photo ,  color: Colors.blueAccent),
                          onPressed: () {

                            _openGalleryAndUploadImage(
                                widget.convsController,
                                widget.currentUser,
                                widget.selectedUser.id!,
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
                        sendMessage(widget.convsController, widget.currentUser, widget.selectedUser.id!,
                            messageController.text, "",  widget.socket, widget.convsIndex);
                        messageController.text = "";

                        if(widget.typingUsersId.contains(widget.currentUser.id)){ //notifying other user that current user is  not typing...

                          widget.typingUsersId.remove(widget.currentUser.id);
                          String typingEvent = "typing"; //sending event name...

                          var json = {
                            "convsId": widget.convsController.conversations[widget.convsIndex].id,
                            "convsType": widget.convsController.conversations[widget.convsIndex].type,
                            "typingUsersId": widget.typingUsersId};


                          widget.socket.emit(typingEvent, json);

                        }

                      }else{
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
                  onEmojiSelected: (category, emoji)=>{
                  setState(() {

                  })
                  },

                  config: Config(
                    columns: 7,
                    // Issue: https://github.com/flutter/flutter/issues/28894
                    emojiSizeMax: 32 *
                        (foundation.defaultTargetPlatform ==
                            TargetPlatform.iOS
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
      int convsIndex
      ) async {
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
          messageController.text, response.data['url'], socket, convsIndex);
    } catch (e) {
      print(e.toString());
    }
  }
}

abstract class OnMessageSend{
  void onMessageSend();
}











