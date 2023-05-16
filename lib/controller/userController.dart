import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:realtime_chat/view/conversation_list_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../view/user_list_page.dart';

class UserController extends GetxController {
  var users = <User>[].obs;
  final dio = Dio();

  createUser(
      BuildContext context,
      UserController userController,
      ConversationController convsController,
      String chatId,
      String name,
      String email,
      String password,
      IO.Socket socket) async {
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.post(
      'http://172.28.240.1:3000/user/add',
      data: jsonEncode(<String, String>{
        "chatId": chatId,
        "name": name,
        "email": email,
        "password": password
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
                  ConversationListPage(userController, convsController, user, socket)));
    }
  }

  void getUsersData() async {
    users.clear();
    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var responce = await dio.get(
      'http://172.28.240.1:3000/user/get',
      options: Options(headers: header),
    );
    if (responce.statusCode == 200) {
      var result = jsonDecode(responce.data);
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
      'http://172.28.240.1:3000/user/get',
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
  }

  void verifyUserData(
      BuildContext context,
      String chatId,
      UserController userController,
      ConversationController convsController,
      String userName,
      String userEmail,
      String userPassword,
      IO.Socket socket) async {
    users.clear();

    var header = {
      'Content-type': 'application/json; charset=utf-8',
      'Accept': 'application/json'
    };
    var response = await dio.get(
      "http://172.28.240.1:3000/user/get?email=${userEmail}&password=${userPassword}",
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
        print("Users: " + userController.users.length.toString());
        String userId = userController.users[0].id!;
        userController.updateUserChatId(context, userId, chatId, userController,
            userName, userEmail, userPassword);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ConversationListPage(userController,
                  convsController, userController.users[0], socket)),
        );
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
      'http://172.28.240.1:3000/user/updateChatId',
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
