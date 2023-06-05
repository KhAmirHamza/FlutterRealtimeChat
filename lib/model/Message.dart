import 'package:realtime_chat/model/User.dart';

class Message {
  String? id;
  User? from;
  String? to;
  String? text;
  List<String>? seenBy;
  List<String>? receivedBy;
  String? imageUrl;
  List<React>? reacts;
  ReplyOf? replyOf;
  String? createdAt;
  String? updatedAt;

  Message({this.id, this.from, this.to, this.text, this.seenBy, this.receivedBy, this.imageUrl, this.reacts, this.replyOf, this.createdAt, this.updatedAt});

  Message.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    from = json['from'] != null ? new User.fromJson(json['from']) : null;
    to = json['to'];
    text = json['text'];
    seenBy = json['seenBy'].cast<String>();
    receivedBy = json['receivedBy'].cast<String>();
    imageUrl = json['imageUrl'];
    if (json['reacts'] != null) {
      reacts = <React>[];
      json['reacts'].forEach((v) {
        reacts!.add(new React.fromJson(v));
      });
    }
    replyOf = json['replyOf'] != null ? new ReplyOf.fromJson(json['replyOf']) : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    if (this.from != null) {
      data['from'] = this.from!.toJson();
    }
    data['to'] = this.to;
    data['text'] = this.text;
    data['seenBy'] = this.seenBy;
    data['receivedBy'] = this.receivedBy;
    data['imageUrl'] = this.imageUrl;
    if (this.reacts != null) {
      data['reacts'] = this.reacts!.map((v) => v.toJson()).toList();
    }
    if (this.replyOf != null) {
      data['replyOf'] = this.replyOf!.toJson();
    }
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}



class React {
  String? title;
  String? userId;

  React({this.title, this.userId});

  React.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    userId = json['userId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['userId'] = this.userId;
    return data;
  }
}

class ReplyOf {
  String? id;
  User? from;
  String? to;
  String? senderName;
  String? text;
  String? imageUrl;
  ReplyOf({this.id, this.from, this.to, this.senderName, this.text, this.imageUrl});

  ReplyOf.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    from = json['from'] != null ? new User.fromJson(json['from']) : null;
    to = json['to'];
    senderName = json['senderName'];
    text = json['text'];
    imageUrl = json['imageUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    if (this.from != null) {
      data['from'] = this.from!.toJson();
    }
    data['to'] = this.to;
    data['senderName'] = this.senderName;
    data['text'] = this.text;
    data['imageUrl'] = this.imageUrl;
    return data;
  }


}


//
// class From {
//   String? id;
//   String? chatId;
//   String? name;
//   String? imageUrl;
//   String? email;
//   String? status;
//   String? createdAt;
//
//   From(
//       {this.id,
//         this.chatId,
//         this.name,
//         this.imageUrl,
//         this.email,
//         this.status,
//         this.createdAt});
//
//   From.fromJson(Map<String, dynamic> json) {
//     id = json['_id'];
//     chatId = json['chatId'];
//     name = json['name'];
//     imageUrl = json['imageUrl'];
//     email = json['email'];
//     status = json['status'];
//     createdAt = json['createdAt'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['_id'] = this.id;
//     data['chatId'] = this.chatId;
//     data['name'] = this.name;
//     data['imageUrl'] = this.imageUrl;
//     data['email'] = this.email;
//     data['status'] = this.status;
//     data['createdAt'] = this.createdAt;
//     return data;
//   }
// }
