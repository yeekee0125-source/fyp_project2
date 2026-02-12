import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../screens/recipe/view_recipe.dart';
import '../services/interaction_service.dart';

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final InteractionService _service = InteractionService();
    // Use tryParse to handle cases where ID might not be a valid int
    final int recipeId = int.tryParse(recipe.id) ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViewRecipePage(recipe: recipe)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // --- Recipe Image (Maintains box even if empty) ---
            Hero(
              tag: 'recipe-image-${recipe.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 110,
                  height: 110,
                  color: const Color(0xFFFFF9E6), // The "box" color
                  child: recipe.imagePath != null && recipe.imagePath!.isNotEmpty
                      ? Image.network(
                    recipe.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.orange),
                  )
                      : const Icon(Icons.restaurant, color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // --- Recipe Info ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('${recipe.cookingTime} mins', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      const Text("•", style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Text(
                        recipe.skillLevel ?? "Easy",
                        style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // --- Real-time Interaction Stats ---
                  Row(
                    children: [
                      // REAL-TIME LIKES (No longer using recipe.totalLikes)
                      StreamBuilder<int>(
                        stream: _service.getLikeCountStream(recipeId),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return _buildMiniStat(Icons.favorite, "$count", Colors.red);
                        },
                      ),
                      const SizedBox(width: 12),
                      // REAL-TIME SAVES
                      StreamBuilder<int>(
                        stream: _service.getSaveCountStream(recipeId),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return _buildMiniStat(Icons.bookmark, "$count", Colors.amber.shade800);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}