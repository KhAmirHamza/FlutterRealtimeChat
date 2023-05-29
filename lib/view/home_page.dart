import 'dart:convert';
import 'dart:math';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:realtime_chat/controller/userController.dart';
import 'package:realtime_chat/model/Conversation.dart';
import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:realtime_chat/view/ContactPage.dart';
import 'package:realtime_chat/view/DiscoverPage.dart';
import 'package:realtime_chat/view/MeetingPage.dart';
import 'package:realtime_chat/view/WorkPage.dart';
import 'package:realtime_chat/view/conversation_list_widget.dart';
import 'package:realtime_chat/view/create_group.dart';
import 'package:realtime_chat/view/group_chat_widget.dart';
import 'package:realtime_chat/view/p_to_p_chat_page.dart';
import 'package:realtime_chat/view/user_list_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class HomePage extends StatefulWidget {
  final IO.Socket socket;
  final User currentUser;
  final UserController userController;
  final ConversationController convsController;


  HomePage(
      this.userController, this.currentUser, this.socket, this.convsController,
      {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var activeUsers = [];

  int _page = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  List<Widget> pages = [];

  void OnTapped(int index) {
    setState(() {
      _page = index;
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    pages = [
      ConversationListWidget(widget.userController,  widget.currentUser, widget.socket, widget.convsController),
      MeetingPage(), WorkPage(), ContactPage(), DiscoverPage()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: 0,
          height: 50.0,
          items: const <Widget>[
            Padding(
              padding: EdgeInsets.all(3.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 25),
                  Text(
                    "Messages",
                    style: TextStyle(fontSize: 10),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.video_call_outlined, size: 25),
                  Text(
                    "Meetings",
                    style: TextStyle(fontSize: 10),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.workspaces_outlined, size: 25),
                  Text(
                    "Work",
                    style: TextStyle(fontSize: 10),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.contact_phone_outlined, size: 25),
                  Text(
                    "Contacts",
                    style: TextStyle(fontSize: 10),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.ac_unit_outlined, size: 25),
                  Text(
                    "Discover",
                    style: TextStyle(fontSize: 10),
                  )
                ],
              ),
            ),
          ],
          color: Colors.white,
          buttonBackgroundColor: Colors.blue.shade50,
          backgroundColor: Colors.white,
          animationCurve: Curves.easeInOutCubic,
          animationDuration: Duration(milliseconds: 450),
          onTap: (index) {
            setState(() {
              _page = index;
            });
          },
          letIndexChange: (index) => true,



        ),
        body: pages[_page]);
  }
}


