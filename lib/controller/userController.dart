import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:realtime_chat/view/home_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../view/create_group.dart';
import '../view/user_list_page.dart';

class UserController extends GetxController {
  var users = <User>[].obs;
  final dio = Dio();

  createUser(
      BuildContext context,
      UserController userController,
      String chatId,
      String name,
      String imageUrl,
      String email,
      String password,
      IO.Socket socket, ConversationController convsController) async {
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.post(
     // 'http://172.28.240.1:3000/user/add',
      'https://nodejsrealtimechat.onrender.com/user/add',
      data: jsonEncode(<String, String>{
        "chatId": chatId,
        "name": name,
        "imageUrl": imageUrl,
        "email": email,
        "password": password,
        "status": "Online",
      }),
      options: Options(headers: header),
    );
    if (response.statusCode == 200) {

      print("response");
      //print(response.data);
      User user = User.fromJson(response.data);

      //User user = new User(id: "jfgjk",name: name, email: email, password: password);
        users.add(user);
        print(user.id);

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomePage(userController, user, socket, convsController)));
    }
  }

  void getUsersData() async {
    users.clear();
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var responce = await dio.get(
//'http://172.28.240.1:3000/user/get',
      'https://nodejsrealtimechat.onrender.com/user/get',
      options: Options(headers: header),
    );
    if (responce.statusCode == 200) {
      var result = responce.data;
      for (int i = 0; i < result.length; i++) {
        User user = User.fromJson(result[i]);
        users.add(user);
      }
    }
  }

  void getUsersDataExceptOne(name, email) async {
    users.clear();

    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.get(
      'https://nodejsrealtimechat.onrender.com/user/get',
   //   'http://172.28.240.1:3000/user/get',
      options: Options(headers: header),
    );
    if (response.statusCode == 200) {
      var result = response.data;
      for (int i = 0; i < result.length; i++) {
        User user = User.fromJson(result[i]);

        if (user.name == name && user.email == email) {
          print(user.name! + ": " + name + ", " + user.email! + ": " + email);
        } else {
          print(user.name! + ": " + name + ", " + user.email! + ": " + email);
          users.add(user);
        }
      }
      print('users: ' + users.length.toString());
    }

    users.refresh();

  }

  void verifyUserData(
      BuildContext context,
      String chatId,
      UserController userController,
      String userName,
      String userEmail,
      String userPassword,
      IO.Socket socket, ConversationController convsController) async {
    users.clear();

    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.get(//verify User
      "https://nodejsrealtimechat.onrender.com/user/get?email=${userEmail}&password=${userPassword}",
 //     "http://172.28.240.1:3000/user/get?email=${userEmail}&password=${userPassword}",
      options: Options(headers: header),
    );

    if (response.statusCode == 200) {
      var result = response.data;
      print(response.data);

      for (int i = 0; i < result.length; i++) {
        User user = User.fromJson(result[i]);
        users.add(user);
      }
      if (userController.users.isNotEmpty) {

        socket.emit("new-user-add", {users[0].id, users[0].chatId});

        print("Users: " + userController.users.length.toString());
        String userId = userController.users[0].id!;
        userController.updateUserChatId(context, userId, chatId, userController,
            userName, userEmail, userPassword);


        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
           // CreateGroupWidget(userController, convsController, users[0], socket)
     HomePage(userController,userController.users[0], socket, convsController)
          ));


      }
    }
  }

  void updateUserChatId(
      BuildContext context,
      String id,
      String chatId,
      UserController userController,
      String name,
      String email,
      String password) async {
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.post(
     //'http://172.28.240.1:3000/user/updateChatId',
     'https://nodejsrealtimechat.onrender.com/user/updateChatId',
      data: jsonEncode(<String, String>{
        '_id': id,
        'chatId': chatId,
      }),
      options: Options(headers: header),
    );
    if (response.statusCode == 200) {
      print("Chat Id Successfully Updated!");
    }
  }
}
