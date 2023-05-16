import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';

class Conversation {
  String? id;
  List<User>? users;
  List<Message>? messages;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Conversation(
      {this.id,
      this.users,
      this.messages,
      this.createdAt,
      this.updatedAt,
      this.iV});

  Conversation.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    if (json['users'] != null) {
      users = <User>[];
      json['users'].forEach((v) {
        users!.add(new User.fromJson(v));
      });
    }

    if (json['messages'] != null) {
      messages = <Message>[];
      json['messages'].forEach((v) {
        messages!.add(new Message.fromJson(v));
      });
    }

    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    if (this.users != null) {
      data['users'] = this.users!.map((v) => v.toJson()).toList();
    }

    if (this.messages != null) {
      data['messages'] = this.messages!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
