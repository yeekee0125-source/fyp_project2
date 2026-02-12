class RecipeModel {
  final String id;
  final String title;
  final String ingredients;
  final String steps;
  final List<String> category;
  final int servings;
  final String? imagePath;
  final String status;
  final DateTime createdOn;
  final int cookingTime;
  final String? skillLevel;
  final int totalViews;
  final String userId;

  RecipeModel({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.category,
    required this.servings,
    this.imagePath,
    this.status = 'pending',
    required this.createdOn,
    this.cookingTime = 0,
    this.skillLevel,
    this.totalViews = 0,
    required this.userId,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      ingredients: json['ingredients']?.toString() ?? '',
      steps: json['steps']?.toString() ?? '',
      category: json['category'] is List
          ? List<String>.from(json['category'])
          : (json['category'] != null ? [json['category'].toString()] : []),
      servings: json['servings'] ?? 1,
      imagePath: json['imagePath']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdOn: json['createdOn'] != null
          ? DateTime.parse(json['createdOn'].toString())
          : DateTime.now(),
      cookingTime: json['cookingTime'] ?? 0,
      skillLevel: json['skillLevel']?.toString() ?? 'Beginner',
      totalViews: json['totalViews'] ?? 0,
      userId: json['user_id']?.toString() ?? '', // Linked to creator
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'ingredients': ingredients,
      'steps': steps,
      'category': category,
      'servings': servings,
      'imagePath': imagePath,
      'status': status,
      'createdOn': createdOn.toIso8601String(),
      'cookingTime': cookingTime,
      'skillLevel': skillLevel,
      'totalViews': totalViews,
      'user_id': userId,
    };
  }
}