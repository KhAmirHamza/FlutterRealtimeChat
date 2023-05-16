class Message {
  String? id;
  String? fromId;
  String? toId;
  String? text;
  List<String>? seenBy;
  String? imageUrl;

  Message(
      {this.id, this.fromId, this.toId, this.text, this.seenBy, this.imageUrl});

  Message.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    fromId = json['fromId'];
    toId = json['toId'];
    text = json['text'];
    seenBy = json['seenBy'].cast<String>();
    imageUrl = json['imageUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['fromId'] = this.fromId;
    data['toId'] = this.toId;
    data['text'] = this.text;
    data['seenBy'] = this.seenBy;
    data['imageUrl'] = this.imageUrl;
    return data;
  }
}
