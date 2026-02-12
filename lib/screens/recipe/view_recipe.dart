import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../services/interaction_service.dart';
import '../../widgets/recipe_interaction_bar.dart';

class ViewRecipePage extends StatelessWidget {
  final RecipeModel recipe;
  const ViewRecipePage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final interactionService = InteractionService();
    // Logic check: Is this the current logged-in user's recipe?
    final bool isOwnRecipe = interactionService.currentUserId == recipe.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // 1. HERO IMAGE BOX
          _buildHeroImage(),

          const SizedBox(height: 15),

          // 2. CREATOR HEADER (Clean Name & Follower Count)
          _buildUserHeader(interactionService, isOwnRecipe),

          const SizedBox(height: 15),

          // 3. RECIPE TITLE
          Text(
              recipe.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))
          ),

          const SizedBox(height: 10),

          // 4. INTERACTION BAR (Likes/Saves)
          RecipeInteractionBar(recipeId: int.parse(recipe.id)),

          const SizedBox(height: 20),

          // 5. RECIPE DETAILS GRID
          _buildDetailsGrid(),

          const SizedBox(height: 25),

          _sectionTitle('Ingredients'),
          _contentBox(recipe.ingredients),

          _sectionTitle('Instructions'),
          _contentBox(recipe.steps),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5A5),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: recipe.imagePath != null && recipe.imagePath!.isNotEmpty
              ? (recipe.imagePath!.startsWith('http')
              ? Image.network(recipe.imagePath!, fit: BoxFit.cover)
              : Image.file(File(recipe.imagePath!), fit: BoxFit.cover))
              : const Icon(Icons.restaurant, size: 80, color: Colors.orange),
        ),
      ),
    );
  }

  Widget _buildUserHeader(InteractionService service, bool isMe) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: service.getCreatorProfile(recipe.userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        // Display 'name' from DB or default to 'Chef'
        final String displayName = profile?['name'] ?? "Chef";

        return Row(
          children: [
            // Simplified: Replaced avatar with a clean account icon
            const Icon(Icons.account_circle, size: 45, color: Colors.brown),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5D4037))
                ),
                // Real-time Follower Count
                StreamBuilder<int>(
                  stream: service.getFollowerCountStream(recipe.userId),
                  builder: (context, countSnapshot) {
                    final count = countSnapshot.data ?? 0;
                    return Text("$count Followers", style: const TextStyle(fontSize: 12, color: Colors.grey));
                  },
                ),
              ],
            ),
            const Spacer(),
            // Only show follow button if it's not the user's own recipe
            if (!isMe)
              StreamBuilder<bool>(
                stream: service.isFollowingStream(recipe.userId),
                builder: (context, followSnapshot) {
                  final isFollowing = followSnapshot.data ?? false;
                  return ElevatedButton(
                    onPressed: () {
                      if (recipe.userId.isNotEmpty) {
                        service.toggleFollow(recipe.userId, isFollowing);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey[300] : Colors.orange,
                      foregroundColor: isFollowing ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(isFollowing ? "Following" : "Follow"),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(Icons.access_time, "${recipe.cookingTime}m", "Time"),
          _infoItem(Icons.people_outline, "${recipe.servings}", "Servings"),
          _infoItem(Icons.bar_chart, recipe.skillLevel ?? "Easy", "Level"),
          _infoItem(Icons.visibility_outlined, "${recipe.totalViews}", "Views"),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(title, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }

  Widget _contentBox(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
    );
  }
}