import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:realtime_chat/controller/SocketController.dart';
import 'package:realtime_chat/view/create_group.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';
import 'controller/userController.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}




class _MyAppState extends State<MyApp> {

  final convsController = Get.put(ConversationController());


  Socket? socket ;

  @override
  void initState(){
    super.initState();
    SocketController socketController = SocketController();
    socket =  socketController.getInstance();

  }


  @override
  void dispose() {
    if(socket!=null) {
      socket!.disconnect();
    }
    super.dispose();
}
  @override
  Widget build(BuildContext context) {


    var userController = Get.put(UserController());


    return MaterialApp(
        title: 'Flutter Realtime Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(

          body: MainWidget( userController, socket!, convsController),
        ));
  }
}

class MainWidget extends StatefulWidget {

  IO.Socket socket;
  UserController userController;
  ConversationController convsController;
  MainWidget( this.userController, this.socket, this.convsController,
      {super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Container(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Container(
                margin: EdgeInsets.only(bottom: 30),
                child: Text("Realtime Chat",
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),


          Expanded(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Name",
                  hintText: "Enter Your Name",
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Email",
                  hintText: "Enter Your Email Address",
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter Password',
                ),
              ),
            ),
          ),
          MyButton(widget.userController, nameController, emailController, passwordController, widget.socket, widget.convsController),
          JoinButton( widget.userController, nameController, emailController, passwordController, widget.socket, widget.convsController),
        ],
      ),
    );
  }
}

class MyButton extends StatelessWidget {
  UserController userController;
  var nameController, emailController, passwordController;
  ConversationController convsController;
  IO.Socket socket;
  MyButton(this.userController,
      this.nameController, this.emailController, this.passwordController,
      this.socket,this.convsController,
      {super.key});

  @override
  Widget build(BuildContext context) {



    return GestureDetector(
      onTap: () {

        userController.createUser(
            context,
            userController,
            socket.id!,
            nameController.text,
            "imageUrl",
            emailController.text,
            passwordController.text,
            socket, convsController);
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: Colors.lightGreen[500],
        ),
        child: const Center(
          child: Text('Create'),
        ),
      ),
    );
  }
}

class JoinButton extends StatelessWidget {
  UserController userController;
  var nameController, emailController, passwordController;
  ConversationController convsController;
  IO.Socket socket;

  JoinButton(this.userController, this.nameController, this.emailController, this.passwordController, this.socket, this.convsController,
      {super.key});

  @override
  Widget build(BuildContext context) {


    return GestureDetector(
      onTap: () {
        // print(nameController.text);
        userController.verifyUserData(
            context,
            socket.id!,
            userController,
            nameController.text,
            emailController.text,
            passwordController.text,
            socket, convsController);
      },
      child: Container(
        height: 50.0,
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: Color.fromARGB(255, 14, 188, 159),
        ),
        child: const Center(
          child: Text('Join'),
        ),
      ),
    );
  }
}


