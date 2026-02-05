import 'dart:io';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'recipe_model.dart';
import 'recipe_service.dart';
import 'view_recipe.dart';


class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final db = DatabaseService();

  Widget _buildRecipeCard(RecipeModel recipe) {
    return Card(
      color: const Color(0xFFFFE5A5),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
          leading: recipe.imagePath != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(recipe.imagePath!),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          )
              : const Icon(Icons.restaurant_menu, color: Colors.orange),
          title: Text(
            recipe.title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          subtitle: Text(recipe.category, style: const TextStyle(color: Colors.black54)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
          onTap: () async {
            // Navigates to the Detail page as required by your functional objectives [cite: 89, 732]
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewRecipePage(recipe: recipe),
              ),
            );

            // If the user deleted or updated the recipe, result will be true [cite: 835, 854]
            // Calling setState tells the FutureBuilder to run fetchRecipes() again [cite: 496]
            if (result == true) {
              setState(() {});
            }
          }
      ),
    );}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main Background Yellow
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF3CC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Recipes',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange, // Matching the "Add" button style
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRecipePage()),
          );
          if (result == true) setState(() {});
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<RecipeModel>>(
        future: db.fetchRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final recipes = snapshot.data ?? [];

          if (recipes.isEmpty) {
            return const Center(
              child: Text(
                'No recipes yet. Add one 🍳',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10),
            itemCount: recipes.length,
            itemBuilder: (_, i) {
              final recipe = recipes[i];
              return _buildRecipeCard(recipe);
            },
          );
        },
      ),
    );
  }
}
