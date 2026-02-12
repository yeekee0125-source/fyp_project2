import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';

class SearchService {
  final _supabase = Supabase.instance.client;

  Future<List<RecipeModel>> searchRecipes({
    String? keyword,
    String? category,
    String? skillLevel,
    int? maxTime,
    List<String>? fullCategoryList, // Pass the hardcoded list here for "Other" logic
  }) async {
    // If the user clicks "Other", we redirect to the custom logic
    if (category == 'Other' && fullCategoryList != null) {
      return await getCustomCategories(excludeList: fullCategoryList);
    }

    var request = _supabase.from('recipes').select().eq('status', 'approved');

    if (keyword != null && keyword.isNotEmpty) {
      request = request.ilike('title', '%$keyword%');
    }

    // Standard Category filter
    if (category != null && category != 'All' && category != 'All Categories') {
      request = request.contains('category', [category]);
    }

    if (maxTime != null) {
      request = request.lte('cookingTime', maxTime);
    }

    final response = await request.order('totalViews', ascending: false);    return response.map<RecipeModel>((json) => RecipeModel.fromJson(json)).toList();
  }

  Future<List<RecipeModel>> getCustomCategories({required List<String> excludeList}) async {
    try {
      // 1. Remove non-category labels from the list
      List<String> cleanExcludeList = excludeList
          .where((e) => e != 'All Categories' && e != 'Other')
          .toList();

      // 2. Fetch all approved recipes
      final response = await _supabase
          .from('recipes')
          .select()
          .eq('status', 'approved');

      final allRecipes = (response as List).map((json) => RecipeModel.fromJson(json)).toList();

      // 3. Filter locally: Find recipes whose categories are NOT in the cleanExcludeList
      // This is often more reliable for Supabase array 'not contains' logic
      return allRecipes.where((recipe) {
        return recipe.category.any((cat) => !cleanExcludeList.contains(cat));
      }).toList();

    } catch (e) {
      print('Error fetching custom categories: $e');
      return [];
    }
  }
}