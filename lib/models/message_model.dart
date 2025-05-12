class MessageModel {
  final String? id;
  final String receiverId;
  final String content;
  final String listingId;

  MessageModel({
    this.id,
    required this.receiverId,
    required this.content,
    required this.listingId,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiverId': receiverId,
      'content': content,
      'listingId': listingId,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'],
      receiverId: json['receiverId'],
      content: json['content'],
      listingId: json['listingId'],
    );
  }
}
