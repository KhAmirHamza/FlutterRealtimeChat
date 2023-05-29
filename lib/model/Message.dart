import 'package:realtime_chat/model/User.dart';

class Message {
  String? id;
  User? from;
  String? to;
  String? text;
  List<String>? seenBy;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;

  Message({this.id, this.from, this.to, this.text, this.seenBy, this.imageUrl, this.createdAt, this.updatedAt});

  Message.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    from = json['from'] != null ? new User.fromJson(json['from']) : null;
    to = json['to'];
    text = json['text'];
    seenBy = json['seenBy'].cast<String>();
    imageUrl = json['imageUrl'];
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
    data['imageUrl'] = this.imageUrl;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
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
