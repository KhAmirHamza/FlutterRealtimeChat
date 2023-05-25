class User {
  String? id;
  String? chatId;
  String? name;
  String? imageUrl;
  String? email;
  String? password;
  String? status;

  User({this.id, this.chatId, this.name, this.email, this.password});

  User.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    chatId = json['chatId'];
    name = json['name'];
    imageUrl = json['imageUrl'];
    email = json['email'];
    password = json['password'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['chatId'] = this.chatId;
    data['name'] = this.name;
    data['imageUrl'] = this.imageUrl;
    data['email'] = this.email;
    data['password'] = this.password;
    data['status'] = this.status;
    return data;
  }
}
