import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_getx_widget.dart';
import 'package:realtime_chat/controller/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../controller/ConvsCntlr.dart';
import '../model/Message.dart';
import '../model/User.dart';
import 'home_page.dart';

List<User> groupUsers = <User>[];

class CreateGroupWidget extends StatefulWidget {
  UserController userController;
  ConversationController convsController;
  User currentUser;
  IO.Socket socket;

  CreateGroupWidget(
      this.userController, this.convsController, this.currentUser, this.socket,
      {Key? key})
      : super(key: key);

  @override
  State<CreateGroupWidget> createState() => _CreateGroupWidgetState();
}

class _CreateGroupWidgetState extends State<CreateGroupWidget> {
  final searchController = Get.put(SearchController());


  refresh(List<User> users) {
    setState(() {
      groupUsers = users;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.userController.getUsersDataExceptOne(widget.currentUser.name, widget.currentUser.email);
    });
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: BackButton(
          color: Colors.black,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          "Create a Group Chat",
          style: TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () {
              //method to show the search bar
              showSearch(
                  context: context,
                  // delegate to customize the search bar
                  delegate:
                      CustomSearchDelegate(widget.userController, refresh));
            },
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
          )
        ],
      ),
      body: GroupWidget(widget.userController, widget.convsController,
          widget.currentUser, widget.socket),
    );
  }
}

class GroupWidget extends StatefulWidget {
  UserController userController;

  ConversationController convsController;
  User currentUser;

  //List<User> users = <User>[];
  IO.Socket socket;

  GroupWidget(
      this.userController, this.convsController, this.currentUser, this.socket,
      {Key? key})
      : super(key: key);

  @override
  State<GroupWidget> createState() => _GroupWidgetState();
}

class _GroupWidgetState extends State<GroupWidget>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    refresh(List<User> users) {
      setState(() {
        groupUsers = users;
      });
    }

    final random = Random();

    // Generate a random color.
    var _color = Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );

    // Generate a random border radius.
    var _borderRadius = BorderRadius.circular(random.nextInt(100).toDouble());


    return Container(
      margin: EdgeInsets.fromLTRB(10, 7, 10, 10),
      child: Column(
        children: [
          MaterialButton(
              padding: EdgeInsets.only(left: 5),
              height: 50,
              onPressed: () {},
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17.0,
                    child: Icon(
                      Icons.person, color: Colors.white,
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 15),
                    child: Text(
                      "Friends",
                      style: TextStyle(fontSize: 17, color: Colors.black),
                    ),
                  )
                ],
              )),
          MaterialButton(
              padding: EdgeInsets.only(left: 5),
              height: 50,
              onPressed: () {},
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17.0,
                    child: Icon(
                      Icons.contact_phone_sharp, color: Colors.white, size: 18,
                    ),
                    backgroundColor: Colors.cyan[700],
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 15),
                    child: Text(
                      "Contacts",
                      style: TextStyle(fontSize: 17, color: Colors.black),
                    ),
                  )
                ],
              )),
          MaterialButton(
              padding: EdgeInsets.only(left: 5),
              height: 50,
              onPressed: () {},
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17.0,
                    child: Icon(
                      Icons.group_rounded, color: Colors.white,
                    ),
                    backgroundColor: Colors.green,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 15),
                    child: Text(
                      "Select aGroup",
                      style: TextStyle(fontSize: 17, color: Colors.black),
                    ),
                  )
                ],
              )),

          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(25.0),
          //     boxShadow: [
          //       BoxShadow(
          //           offset: Offset(0, 3), blurRadius: 7, color: Colors.blueGrey)
          //     ],
          //   ),
          //   child: Container(
          //     margin: EdgeInsets.symmetric(horizontal: 25),
          //     child: Material(
          //       child: TextField(
          //         controller: searchController,
          //         decoration: const InputDecoration(
          //           icon: Icon(Icons.search),
          //           hintText: "Search User...",
          //           hintStyle: TextStyle(color: Colors.grey),
          //           border: InputBorder.none,
          //         ),
          //         onChanged: (text) {
          //           //todo.... search user...
          //         },
          //       ),
          //     ),
          //   ),
          // ),
          Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.fromLTRB(5, 10, 0, 5),
            child: Text(
              "Select Contact",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(child: GetX<UserController>(
            builder: (controller) {
              return ListView.builder(
                  itemCount: widget.userController.users.length,
                  itemBuilder: (context, index) {
                    return EmployeeItem(widget.userController, index, refresh);
                  });
            },
          )),

          Card(
              margin: EdgeInsets.all(5),
              elevation: 2,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.white70, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  Expanded(
                    flex: 3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      // Provide an optional curve to make the animation feel smoother.
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      //margin: EdgeInsets.fromLTRB(5,5,5,5),
                      height: groupUsers.isEmpty ? 0 : 80,
                      curve: Curves.fastOutSlowIn,
                      padding: EdgeInsets.fromLTRB(5, 0, 5, 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              alignment: Alignment.topLeft,
                              margin: EdgeInsets.fromLTRB(5, 5, 5, 0),
                              child: Text(
                                "Selected Contact: ( ${groupUsers.length} )",
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: ListView.builder(
                              //physics: const NeverScrollableScrollPhysics(),
                              itemCount: groupUsers.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                // return EmployeeItem(selecteUsers, index);
                                int animDuraton = 2000;
                                if (index > 0) animDuraton = 1000;

                                AnimationController _controller = AnimationController(
                                    vsync: this,
                                    duration: Duration(milliseconds: animDuraton));

                                return SelectedUserWidget(_controller, index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.bottomRight,
                      //margin: EdgeInsets.all(5),
                      child: MaterialButton(
                        color: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22.0)),
                        clipBehavior: Clip.antiAlias,
                        elevation: 8,
                        onPressed: () {
                          //todo... goto next page

                          showCustomDialog(
                              context,
                              widget.convsController,
                              widget.userController,
                              widget.currentUser,
                              widget.socket);
                        },
                        child: Text("Next", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  )
                ],)

          ),

        ],
      ),
    );
  }
}

class SelectedUserWidget extends StatelessWidget {
  AnimationController animationController;
  int index;
  SelectedUserWidget(this.animationController, this.index, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // _controller.forward().then((value) => _controller.dispose());
    Future.delayed(Duration(milliseconds: index * 300), () {
      animationController.forward().then((_) {
        // Animation finished, clean up the controller.
        animationController.dispose();

        // if (mounted) {
        //   setState(() {});
        // }
      });
    });

    return FadeTransition(
        opacity: animationController,
        child: Container(
          margin: EdgeInsets.fromLTRB(5,10,10,0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                flex: 2,
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                      "https://cdn-icons-png.flaticon.com/512/2815/2815428.png"),
                  backgroundColor: Colors.transparent,
                ),
              ),
              Expanded(
                child: Text(
                  groupUsers[index].name.toString(),
                  style: TextStyle(fontSize: 12),
                ),
              )
            ],
          ),
        ));
  }
}

class EmployeeItem extends StatefulWidget {
  final Function(List<User> users) refresh;
  UserController userController;
  int index;
  EmployeeItem(this.userController, this.index, this.refresh, {Key? key})
      : super(key: key);

  @override
  State<EmployeeItem> createState() => _EmployeeItemState();
}

class _EmployeeItemState extends State<EmployeeItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.fromLTRB(5,0,5,2),
        child: InkWell(
            splashColor: Colors.blue.withAlpha(30),
            onTap: () {
              debugPrint('Card tapped.');
              //todo...

              //select or remove contact

              if (groupUsers
                  .contains(widget.userController.users[widget.index])) {
                groupUsers.remove(widget.userController.users[widget.index]);
              } else {
                groupUsers.add(widget.userController.users[widget.index]);
              }
              //userController.users.refresh();
              widget.refresh(groupUsers);
              setState(() {});
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 10, 0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Container(
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white,
                      backgroundImage: groupUsers.contains(
                              widget.userController.users[widget.index])
                          ? AssetImage('assets/selected.png')
                          : null,
                    ),
                  ),
                ),
                const CircleAvatar(
                  radius: 30.0,
                  backgroundImage: NetworkImage(
                      "https://cdn-icons-png.flaticon.com/512/2815/2815428.png"),
                  backgroundColor: Colors.transparent,
                ),
                Text(widget.userController.users[widget.index].name.toString())
              ],
            )),
      ),
    );
  }
}

void showCustomDialog(
    BuildContext context,
    ConversationController convsController,
    UserController userController,
    User currentUser,
    IO.Socket socket) {
  print("Next Clicked: " + groupUsers.length.toString());

  TextEditingController groupNameController = TextEditingController();

  showGeneralDialog(
    context: context,
    barrierLabel: "Barrier",
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) {
      return Center(
        child: Container(
          height: 300,
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Flexible(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                          offset: Offset(0, 3),
                          blurRadius: 7,
                          color: Colors.blueGrey)
                    ],
                  ),
                  child: Container(
                    margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Material(
                      child: TextField(
                        controller: groupNameController,
                        decoration: const InputDecoration(
                          hintText: "Name of the group",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onChanged: (text) {
                          //todo.... search user...
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.fromLTRB(5, 35, 5, 5),
                child: Text(
                  "Selected Contact",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              Expanded(
                flex: 1,
                  child: ListView.builder(
                      itemCount: groupUsers.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        // return EmployeeItem(selecteUsers, index);
                        return Card(

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: Container(
                            margin: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  radius: 15,
                                  backgroundImage: NetworkImage(
                                      "https://cdn-icons-png.flaticon.com/512/2815/2815428.png"),
                                  backgroundColor: Colors.transparent,
                                ),
                                Text(
                                  groupUsers[index].name.toString(),
                                  style: TextStyle(fontSize: 10),
                                )
                              ],
                            ),
                          ),
                        );
                      })),
              Expanded(
                child: Container(
                  alignment: Alignment.bottomRight,
                  margin: EdgeInsets.all(5),
                  child: MaterialButton(
                    color: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.0)),
                    clipBehavior: Clip.antiAlias,
                    elevation: 8,
                    onPressed: () {
                      //todo... goto next page
                      print("Submit Clicked!");
                      List<String> seenBy = <String>[];
                      seenBy.add(currentUser.id.toString());

                      List<String> receivedBy = <String>[];
                      receivedBy.add(currentUser.id.toString());
                      List<React> reacts = <React>[];

                      Message message = Message(
                          id: "Initial",
                          from: currentUser,
                          to: "All",
                          text: "Initial",
                          seenBy: seenBy,
                          receivedBy: receivedBy,
                          imageUrl:
                          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKTSNwcT2YrRQJKGVQHClGtQgp1_x8kLd0Ig&usqp=CAU",
                          reacts: reacts,
                          replyOf: null );
                      groupUsers.add(currentUser);

                      convsController.sendFirstMessage(context, socket, userController, convsController, currentUser, null, groupUsers,  groupNameController.text, message, "Group");

                      Navigator.of(_, rootNavigator: true).pop();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  HomePage(userController, currentUser, socket, convsController)
                          ));
                    },
                    child: Text("Submit", style: TextStyle(color: Colors.white)),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      Tween<Offset> tween;
      if (anim.status == AnimationStatus.reverse) {
        tween = Tween(begin: Offset(-1, 0), end: Offset.zero);
      } else {
        tween = Tween(begin: Offset(1, 0), end: Offset.zero);
      }

      return SlideTransition(
        position: tween.animate(anim),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      );
    },
  );
}

createGroupConversation(
    BuildContext context,
    ConversationController convsController,
    String title,
    List<User> users,
    UserController userController,
    User currentUser,
    List<Message> messages,
    IO.Socket socket) {
  convsController.createGroupConversation(context, socket, userController,
      convsController, currentUser, "", title, "Group", users, messages);
}

class CustomSearchDelegate extends SearchDelegate {
// Demo list to show querying
  UserController userController;
  final Function(List<User>) refresh;

  CustomSearchDelegate(this.userController, this.refresh);
// first overwrite to
// clear the search text
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

// second overwrite to pop out of search menu
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

// third overwrite to show query result
  @override
  Widget buildResults(BuildContext context) {
    List<User> matchedUsers = [];
    for (var user in userController.users) {
      if (user.name!.toLowerCase().contains(query.toLowerCase())) {
        matchedUsers.add(user);
      }
    }
    return ListView.builder(
      itemCount: userController.users.length,
      itemBuilder: (context, index) {
        return matchedUsers.contains(userController.users[index])
            ? ListTile(title: EmployeeItem(userController, index, refresh))
            : null;
      },
    );
  }

// last overwrite to show the
// querying process at the runtime
  @override
  Widget buildSuggestions(BuildContext context) {
    List<User> matchedUsers = [];
    for (var user in userController.users) {
      if (user.name!.toLowerCase().contains(query.toLowerCase())) {
        matchedUsers.add(user);
      }
    }
    return ListView.builder(
      itemCount: userController.users.length,
      itemBuilder: (context, index) {
        return matchedUsers.contains(userController.users[index])
            ? ListTile(title: EmployeeItem(userController, index, refresh))
            : null;
      },
    );
  }
}
