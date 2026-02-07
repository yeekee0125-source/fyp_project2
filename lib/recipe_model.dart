class RecipeModel {
  final String id;
  final String title;
  final String ingredients;
  final String steps;
  final String category;
  final int servings;
  final String? imagePath;
  final String status;
  final DateTime createdOn;




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

  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      ingredients: json['ingredients']?.toString() ?? '',
      steps: json['steps']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      servings: json['servings'],
      imagePath: json['imagePath']?.toString(),
      status: json['status']?.toString()  ?? 'pending',
      createdOn: json['createdOn'] != null
          ? DateTime.parse(json['createdOn'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ingredients': ingredients,
      'steps': steps,
      'category': category,
      'servings': servings,
      'imagePath': imagePath,
      'status': status,
      'createdOn': createdOn.toIso8601String(),
    };
  }
}
