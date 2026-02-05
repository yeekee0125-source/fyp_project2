class RecipeModel {
  final String id;
  final String title;
  final String ingredients;
  final String steps;
  final String category;
  final int servings;
  final DateTime createdOn;
  final String? imagePath;


  RecipeModel({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.category,
    required this.servings,
    required this.createdOn,
    this.imagePath,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> map) {
    return RecipeModel(
      id: map['id'],
      title: map['title'],
      ingredients: map['ingredients'],
      steps: map['steps'],
      category: map['category'],
      servings: map['servings'],
      createdOn: DateTime.parse(map['createdOn']),
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
      'createdOn': createdOn.toIso8601String(),
    };
  }
}
