class User {
  String? id;
  String? chatId;
  String? name;
  String? email;
  String? password;

  User({this.id, this.chatId, this.name, this.email, this.password});

  User.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    chatId = json['chatId'];
    name = json['name'];
    email = json['email'];
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['chatId'] = this.chatId;
    data['name'] = this.name;
    data['email'] = this.email;
    data['password'] = this.password;
    return data;
  }
}
