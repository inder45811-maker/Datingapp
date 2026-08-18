class MessageModel {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      mediaUrl: json['media_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'sender_id': senderId,
      'content': content,
      'media_url': mediaUrl,
      'is_read': isRead,
    };
  }
}

class MatchSummary {
  final String id;
  final String otherUserId;
  final String otherDisplayName;
  final String? otherPhoto;
  final String? lastMessage;
  final DateTime createdAt;

  MatchSummary({
    required this.id,
    required this.otherUserId,
    required this.otherDisplayName,
    this.otherPhoto,
    this.lastMessage,
    required this.createdAt,
  });
}
