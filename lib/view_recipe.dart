import 'dart:io';
import 'package:flutter/material.dart';
import 'recipe_model.dart';
import 'database_service.dart';
import 'recipe_service.dart';

class ViewRecipePage extends StatelessWidget {
  final RecipeModel recipe;
  const ViewRecipePage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteDialog(context, db),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Image
          if (recipe.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: recipe.imagePath!.startsWith('http')
                  ? Image.network(recipe.imagePath!, fit: BoxFit.cover)
                  : Image.file(File(recipe.imagePath!), fit: BoxFit.cover),
            ),

          const SizedBox(height: 20),

          // Title
          Text(
            recipe.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // Category & Serving
          _infoRow(Icons.category, recipe.category),
          const SizedBox(height: 6),
          _infoRow(Icons.people, 'Servings: ${recipe.servings}'),
          const SizedBox(height: 6),
          _infoRow(
            Icons.calendar_today,
            'Created: ${recipe.createdOn.toLocal().toString().split(' ')[0]}',
          ),

          const Divider(height: 30, color: Colors.orange),

          // Ingredients
          _contentTile('Ingredients', recipe.ingredients),

          // Instructions
          _contentTile('Instructions', recipe.steps),
        ],
      ),

      //update action: floating button to edit
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddRecipePage(recipe: recipe)));
          //if the recipe was updated, go back to list to refresh
          if (result == true) Navigator.pop(context, true);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DatabaseService db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recipe?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await db.deleteRecipe(recipe.id);
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _contentTile(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(content, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.orange),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

}