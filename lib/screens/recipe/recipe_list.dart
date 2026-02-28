import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../services/database_service.dart';
import '../../services/recipe_service.dart';
import 'view_recipe.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();

}

class _RecipeListPageState extends State<RecipeListPage> {
  final db = DatabaseService();

  Future<void> _confirmDelete(BuildContext context, RecipeModel recipe) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to delete "${recipe.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
      );

      try {
        await db.deleteRecipe(recipe.id);

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe deleted successfully'), backgroundColor: Colors.green),
          );
          setState(() {}); // Refresh the list to remove the deleted item
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

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
            child: recipe.imagePath!.startsWith('http')
                ? Image.network(
              recipe.imagePath!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
                : Image.file(
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  recipe.category.isNotEmpty
                      ? recipe.category.join(' • ')
                      : 'Uncategorized',
                  style: const TextStyle(color: Colors.black54)
              ),
              if (recipe.status == 'pending')
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Pending Approval",
                    style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          // Dropdown Menu
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.orange),
            onSelected: (value) async {
              if (value == 'edit') {
                // Navigate to AddRecipePage to edit
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Pass the existing recipe to the AddRecipePage
                    builder: (context) => AddRecipePage(recipe: recipe),
                  ),
                );
                // Refresh the list if they saved changes
                if (result == true) setState(() {});
              } else if (value == 'delete') {
                _confirmDelete(context, recipe);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              ),
            ],
          ),
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
        future: db.fetchMyRecipes(),
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
