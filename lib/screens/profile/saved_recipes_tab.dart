import 'package:flutter/material.dart';
import '../../services/interaction_service.dart';

class SavedRecipesTab extends StatelessWidget {
  final InteractionService _interactionService = InteractionService();

  SavedRecipesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _interactionService.getSavedRecipesStream(),
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        // 2. Error State
        if (snapshot.hasError) {
          return Center(child: Text("Error loading saves: ${snapshot.error}"));
        }

        final recipes = snapshot.data ?? [];

        // 3. Empty State
        if (recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 10),
                const Text("No saved recipes yet",
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        // 4. Data Grid State
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: recipes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,           // 2 columns
            crossAxisSpacing: 12,        // space between columns
            mainAxisSpacing: 12,         // space between rows
            childAspectRatio: 0.85,      // Adjust height/width ratio
          ),
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return _buildRecipeCard(context, recipe);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(BuildContext context, Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to your Recipe Detail Page
        // Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  recipe['imagePath'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                ),
              ),
            ),
            // Recipe Title
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['title'] ?? 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe['category'] ?? 'Recipe',
                    style: TextStyle(color: Colors.orange[700], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}