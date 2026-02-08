import 'package:flutter/material.dart';
import 'database_service.dart';
import 'recipe_model.dart';

class AdminPendingRecipes extends StatelessWidget {
  const AdminPendingRecipes({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Recipes')),
      body: FutureBuilder<List<RecipeModel>>(
        future: db.fetchPendingRecipes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final recipes = snapshot.data!;
          if (recipes.isEmpty) return const Center(child: Text('No pending recipes'));

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (_, i) {
              final r = recipes[i];
              return Card(
                child: ListTile(
                  title: Text(r.title),
                  subtitle: Text(r.category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => db.approveRecipe(r.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => db.rejectRecipe(r.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
