class Message {
  String? id;
  String? fromId;
  String? toId;
  String? text;
  List<String>? seenBy;
  String? imageUrl;
  String? createdAt;
  String? updatedAt;

  Message({this.id, this.fromId, this.toId, this.text, this.seenBy, this.imageUrl, this.createdAt, this.updatedAt});

  Message.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    fromId = json['fromId'];
    toId = json['toId'];
    text = json['text'];
    seenBy = json['seenBy'].cast<String>();
    imageUrl = json['imageUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['fromId'] = this.fromId;
    data['toId'] = this.toId;
    data['text'] = this.text;
    data['seenBy'] = this.seenBy;
    data['imageUrl'] = this.imageUrl;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
