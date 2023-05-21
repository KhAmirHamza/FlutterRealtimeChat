import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
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
  @override
  Widget build(BuildContext context) {


    var userController = Get.put(UserController());
    var convsControler = Get.put(ConversationController());

    return MaterialApp(
        title: 'Flutter Realtime Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          body: JoinWidget( convsControler, userController),
        ));
  }
}

class JoinWidget extends StatefulWidget {
  ConversationController convsController;
  UserController userController;
  JoinWidget(this.convsController, this.userController,
      {super.key});

  @override
  State<JoinWidget> createState() => _JoinWidgetState();
}

class _JoinWidgetState extends State<JoinWidget> {
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
          MyButton(widget.userController, widget.convsController,
              nameController, emailController, passwordController),
          JoinButton( widget.userController, nameController,
              widget.convsController, emailController, passwordController),
        ],
      ),
    );
  }
}

class MyButton extends StatelessWidget {
  UserController userController;
  var nameController, emailController, passwordController;
  ConversationController convsController;
  MyButton(this.userController, this.convsController,
      this.nameController, this.emailController, this.passwordController,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Socket socket = io(
            'https://nodejsrealtimechat.onrender.com/',
            OptionBuilder()
                .setTransports(['websocket']) // for Flutter or Dart VM
                .disableAutoConnect() // disable auto-connection
            //.setExtraHeaders({'foo': 'bar'}) // optional
                .build());
        socket.connect();
        socket.on("connect", (data)  {
          print("Connected: "+ socket.id.toString());
        });

        userController.createUser(
            context,
            userController,
            convsController,
            socket.id!,
            nameController.text,
            emailController.text,
            passwordController.text,
            socket);
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
  JoinButton(this.userController, this.nameController,
      this.convsController, this.emailController, this.passwordController,
      {super.key});

  @override
  Widget build(BuildContext context) {
    Socket socket = io(
        'https://nodejsrealtimechat.onrender.com/',
        OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .disableAutoConnect() // disable auto-connection
        //.setExtraHeaders({'foo': 'bar'}) // optional
            .build());
    socket.connect();
    socket.on("connect", (data)  {
      print("Connected: "+ socket.id.toString());


    });



    return GestureDetector(
      onTap: () {
        // print(nameController.text);
        userController.verifyUserData(
            context,
            socket.id!,
            userController,
            convsController,
            nameController.text,
            emailController.text,
            passwordController.text,
            socket);
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
