class RecipeModel {
  final String id;
  final String title;
  final String ingredients;
  final String steps;
  final String category;
  final int servings;
  final String? imagePath;
  final DateTime createdOn;



  RecipeModel({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.category,
    required this.servings,
    this.imagePath,
    required this.createdOn,

  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'],
      title: json['title'],
      ingredients: json['ingredients'],
      steps: json['steps'],
      category: json['category'],
      servings: json['servings'],
      imagePath: json['imagePath'],
      createdOn: json['createdOn'] != null
          ? DateTime.parse(json['createdOn'])
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
      'createdOn': createdOn.toIso8601String(),
    };
  }
}
