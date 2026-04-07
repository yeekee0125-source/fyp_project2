import 'package:fyp_project2/models/recipe_model.dart';
import 'package:fyp_project2/services/search_service.dart';

class PantryAlgorithm {
  final SearchService _searchService = SearchService();

  Future<List<Map<String, dynamic>>> findMatchingRecipes(List<String> userIngredients) async {
    // 1. Sanitize user inputs
    Set<String> userSet = userIngredients.map((e) => e.toLowerCase().trim()).toSet();

    // 2. Fetch all existing recipes
    List<RecipeModel> allRecipes = await _searchService.searchRecipes(category: 'All Categories');

    List<Map<String, dynamic>> results = [];

    // 3. THE SET-INTERSECTION ALGORITHM
    for (var recipe in allRecipes) {

      // This cuts single string "Egg, Rice" into a list ["Egg", "Rice"] so math works!
      Set<String> recipeSet = recipe.ingredients
          .split(',')
          .map((e) => e.toLowerCase().trim())
          .toSet();

      // Math: Find the overlapping items
      Set<String> intersection = userSet.intersection(recipeSet);

      int matchCount = intersection.length;
      int totalNeeded = recipeSet.length;

      // Only score it if there is at least ONE match
      if (totalNeeded > 0 && matchCount > 0) {
        double percentage = matchCount / totalNeeded;

        results.add({
          'recipe': recipe,
          'percentage': percentage,
          'match_count': matchCount,
          'total_needed': totalNeeded,
        });
      }
    }

    // 4. RANKING ENGINE: Sort from highest percentage to lowest
    results.sort((a, b) => b['percentage'].compareTo(a['percentage']));

    return results;
  }
}