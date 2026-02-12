class VideoModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String skillLevel;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.skillLevel,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'].toString(),
      userId: json['user_id'],
      title: json['title'],
      description: json['description'] ?? '',
      videoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'] ?? '',
      skillLevel: json['skill_level'] ?? 'Beginner',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}