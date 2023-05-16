import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:realtime_chat/main.dart';

class API_Test extends StatelessWidget {
  const API_Test({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "API Tester",
        home: Scaffold(
          appBar: AppBar(title: Text("API Tester")),
          body: Container(
            margin: EdgeInsets.all(20),
            child: GestureDetector(
                onTap: () => executeRequest(), child: Text("Test Now")),
          ),
        ));
  }
}

Future<void> executeRequest() async {
  //var url = Uri.https('example.com', 'whatsit/create');

  Dio dio = Dio();
  var header = {'Content-type': 'application/json; charset=utf-8'};
  var responce = await dio.delete(
    'http://172.27.192.1:5000/',
    options: Options(headers: header),
  );
  if (responce.statusCode == 200) {
    print(responce.data.toString);
  }
}
