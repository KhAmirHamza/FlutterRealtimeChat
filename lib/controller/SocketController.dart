import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';
import '../model/Message.dart';
import '../model/User.dart';

IO.Socket? socket;


final dio = Dio();
 class SocketController {


   SocketController() {
    connectToSocket();
  }

  IO.Socket getInstance(){
    return connectToSocket()!;
  }

   notifyMessageSend(String convsId, String convsType,  Message message, int conversationIndex, ConversationController convsController) {


    sendMessage(convsId, convsType, message, conversationIndex, socket!, convsController);
  }


   notifyMessageReceived(String convsId, String convsType, String currentUserId) {
    //Notify Sender, Receiver has received the Message... Step: 3 //Receiver Page
     print("notify other client that MessageReceived called");

     var json = {"convsId": convsId,"convsType": convsType, "newUserId": currentUserId};
     socket!.emit('notifyMessageReceived', json);
  }

   notifyMessageSeen(String convsId, String convsType, String currentUserId) {
    //Notify Sender, Receiver has seen the Message... Step: 5 //Receiver Page
     print("notify other client that MessageSeen called");

     var json = {"convsId": convsId,"convsType": convsType, "newUserId": currentUserId};
     socket!.emit('notifyMessageSeen', json);
  }

  }


abstract class SocketListeners{
  void onMessageSend(IO.Socket socket, dynamic data, User currentUser); //Sender Send Message...  Step:2 //Receiver Page

  void onMessageReceived(IO.Socket socket, dynamic data, ); //Receiver has received the Message...  Step:4 //Sender Page

  void onMessageSeen(IO.Socket socket, dynamic data); //Receiver has seen the Message...  Step:6 //Sender Page

}


connectToSocket() {
  if (socket != null) {
    return socket;
  }else {
    socket = io(
        'https://nodejsrealtimechat.onrender.com/',
        OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .disableAutoConnect() // disable auto-connection
        //.setExtraHeaders({'foo': 'bar'}) // optional
            .build());
    socket!.connect();
    socket!.on("connect", (data) {
      print("Connected: " + socket!.id.toString());
    });
    return socket!;
  }
}

sendMessage(String convsId, String convsType,  Message message, int conversationIndex, IO.Socket socket, ConversationController convsController) async {
  print(message);

  var header = {
    'Content-type': 'application/json; charset=utf-8',
    'Accept': 'application/json'
  };
  var response = await dio.post(
    // "http://172.28.240.1:3000/conversation/sendMessage?convsId=" + convsId,
    "https://nodejsrealtimechat.onrender.com/conversation/sendMessage?convsId=" + convsId,
    data: jsonEncode(<String, dynamic>{
      '_id': message.id,
      "from": message.from,
      "to": message.to,
      'text': message.text,
      'seenBy': message.seenBy,
      'receivedBy': message.receivedBy,
      'imageUrl': message.imageUrl,
    }),
    options: Options(headers: header),
  );

  Message messageData = Message.fromJson(response.data);

  if (response.statusCode == 200) {
    var json = {
      "_id": messageData.id,
      "from": messageData.from,
      "to": messageData.to,
      "convsId": convsId,
      "convsType": convsType,
      "text": messageData.text,
      "seenBy": messageData.seenBy,
      "receivedBy": messageData.receivedBy,
      'imageUrl': messageData.imageUrl,
      'createdAt': messageData.createdAt,
      'updatedAt': messageData.updatedAt,
    };


    convsController.conversations[conversationIndex].messages!.add(messageData);
    convsController.conversations.refresh();

    socket.emit('sendMessage', json);
    print("Message Send Successfully!");
  }
}

