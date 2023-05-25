import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_getx_widget.dart';
import 'package:realtime_chat/controller/userController.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../controller/ConvsCntlr.dart';
import '../model/Message.dart';
import '../model/User.dart';

List<User> selectedUsers = <User>[] ;

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

  refresh(List<User> users){
    setState(() {
      selectedUsers = users;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: Colors.black,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text("Create a Group Chat"),
        actions: [
          IconButton(
            onPressed: () {
              //method to show the search bar
              showSearch(
                  context: context,
                  // delegate to customize the search bar
                  delegate: CustomSearchDelegate(widget.userController, refresh)
              );
            },
            icon: const Icon(Icons.search),
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
  List<Message> messages = <Message>[];

  //List<User> users = <User>[];
  IO.Socket socket;

  GroupWidget(
      this.userController, this.convsController, this.currentUser, this.socket,
      {Key? key})
      : super(key: key);

  @override
  State<GroupWidget> createState() => _GroupWidgetState();
}

class _GroupWidgetState extends State<GroupWidget> with TickerProviderStateMixin{
  @override
  Widget build(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    refresh(List<User> users){
      setState(() {
        selectedUsers = users;
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
    var _borderRadius =
        BorderRadius.circular(random.nextInt(100).toDouble());

    return Container(
      margin: EdgeInsets.fromLTRB(10, 7, 10, 10),
      child: Column(
        children: [
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
          Card(margin: EdgeInsets.all(5),
            elevation: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              // Provide an optional curve to make the animation feel smoother.
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:BorderRadius.circular(15),
              ),
              //margin: EdgeInsets.fromLTRB(5,5,5,5),
              height: selectedUsers.isEmpty?0:100,
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
                      margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Text(
                        "Selected Contact",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: ListView.builder(
                      //physics: const NeverScrollableScrollPhysics(),
                            itemCount: selectedUsers.length,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              // return EmployeeItem(selecteUsers, index);
                              int animDuraton = 2000;
                              if(index>0) animDuraton = 1000;


                              AnimationController _controller = AnimationController(
                                  vsync: this, duration: Duration(milliseconds: animDuraton));

                              return SelectedUserWidget(_controller, index);

                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.fromLTRB(5, 20, 0, 5),
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
          Container(
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

                showCustomDialog(
                    context,
                    widget.convsController,
                    widget.userController,
                    widget.currentUser,
                    widget.messages,
                    widget.socket);
              },
              child: Text("Next", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}


class SelectedUserWidget extends StatelessWidget {

  AnimationController animationController;
  int index;
  SelectedUserWidget(this.animationController,this.index, {Key? key}) : super(key: key);

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

    return FadeTransition(opacity: animationController,
        child:

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            margin: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  flex:2,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                        "https://cdn-icons-png.flaticon.com/512/2815/2815428.png"),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Text(
                    selectedUsers[index].name.toString(),
                    style: TextStyle(fontSize: 12),
                  ),
                )
              ],
            ),
          ),
        )
    );
  }
}


class EmployeeItem extends StatefulWidget {

  final Function(List<User> users) refresh;
  UserController userController;
  int index;
  EmployeeItem(this.userController, this.index, this.refresh, {Key? key}) : super(key: key);

  @override
  State<EmployeeItem> createState() => _EmployeeItemState();
}

class _EmployeeItemState extends State<EmployeeItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 5,
        child: InkWell(
            splashColor: Colors.blue.withAlpha(30),
            onTap: () {
              debugPrint('Card tapped.');
              //todo...

              //select or remove contact

              if (selectedUsers.contains(widget.userController.users[widget.index])) {
                selectedUsers.remove(widget.userController.users[widget.index]);
              } else {
                selectedUsers.add(widget.userController.users[widget.index]);
              }
              //userController.users.refresh();
              widget.refresh(selectedUsers);
              setState(() {

              });
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
                      backgroundImage:
                          selectedUsers.contains(widget.userController.users[widget.index])
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
    List<Message> messages,
    IO.Socket socket) {
  print("Next Clicked: " + selectedUsers.length.toString());

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
              Container(
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
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.fromLTRB(5, 35, 5, 5),
                child: Text(
                  "Selected Contact",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              Expanded(
                  child: ListView.builder(
                      itemCount: selectedUsers.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        // return EmployeeItem(selecteUsers, index);
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Container(
                            margin: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(
                                      "https://cdn-icons-png.flaticon.com/512/2815/2815428.png"),
                                  backgroundColor: Colors.transparent,
                                ),
                                Text(
                                  selectedUsers[index].name.toString(),
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

                      messages.add(Message(
                          id: "Initial",
                          fromId: "Initial",
                          toId: "Initial",
                          text: "Initial",
                          seenBy: seenBy,
                          imageUrl:
                              "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKTSNwcT2YrRQJKGVQHClGtQgp1_x8kLd0Ig&usqp=CAU"));

                      selectedUsers.add(currentUser);
                      createGroupConversation(
                          context,
                          convsController,
                          groupNameController.text,
                          selectedUsers,
                          userController,
                          currentUser,
                          messages,
                          socket);
                      Navigator.of(_, rootNavigator: true).pop();
                    },
                    child:
                        Text("Submit", style: TextStyle(color: Colors.white)),
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
      convsController, currentUser, "", title,"Group", users, messages);
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
        return matchedUsers.contains(userController.users[index])?
        ListTile(
          title: EmployeeItem(userController, index, refresh)
        ):
            null;
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
        return matchedUsers.contains(userController.users[index])?
        ListTile(
            title: EmployeeItem(userController, index, refresh)
        ):
        null;
      },
    );
  }
}
