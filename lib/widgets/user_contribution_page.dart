import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipe_model.dart';
import '../screens/recipe/view_recipe.dart';

class UserRecipesPage extends StatelessWidget {
  final String userId;
  final String userName;

  const UserRecipesPage({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        title: Text("Recipes by $userName"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: FutureBuilder(
        // Fetching only recipes where user_id matches the clicked creator
        future: supabase.from('recipes').select().eq('user_id', userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error fetching recipes: ${snapshot.error}"));
          }

          final recipes = snapshot.data as List? ?? [];

          if (recipes.isEmpty) {
            return const Center(
              child: Text("This creator hasn't posted any recipes yet."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipeData = recipes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: const Icon(Icons.restaurant_menu, color: Colors.orange, size: 30),
                  title: Text(
                    recipeData['title'] ?? "Untitled",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${recipeData['cookingTime'] ?? 0} mins • ${recipeData['skillLevel'] ?? 'Beginner'}",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewRecipePage(recipe: RecipeModel.fromJson(recipeData)),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}