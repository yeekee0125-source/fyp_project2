import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipe_model.dart';
import '../../widgets/user_contribution_page.dart';
import '../recipe/view_recipe.dart';

class RankingResultsPage extends StatelessWidget {
  final String rankType;

  const RankingResultsPage({super.key, required this.rankType});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        title: Text("Top ${rankType == 'likes' ? 'Recipes' : 'Creators'}"),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: _fetchRankedData(supabase),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final List data = snapshot.data as List;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              String title = "";
              int count = 0;

              if (rankType == 'likes') {
                title = item['title'] ?? "Untitled Recipe";
                count = item['like_count'] ?? 0;
              } else {
                title = item['name'] ?? "User";
                count = item['follower_count'] ?? 0;
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  onTap: () {
                    if (rankType == 'likes') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewRecipePage(recipe: RecipeModel.fromJson(item)),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserRecipesPage(
                            userId: item['id'],
                            userName: item['name'] ?? "User",
                          ),
                        ),
                      );
                    }
                  },
                  leading: _buildRankBadge(index + 1),
                  title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: null,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: Text(
                        "$count",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange
                        )
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<dynamic>> _fetchRankedData(SupabaseClient supabase) async {
    if (rankType == 'likes') {
      final recipes = await supabase.from('recipes').select();
      final likes = await supabase.from('likes').select('recipe_id');

      for (var recipe in recipes) {
        recipe['like_count'] = likes.where((l) => l['recipe_id'] == recipe['id']).length;
      }
      recipes.sort((a, b) => b['like_count'].compareTo(a['like_count']));
      return recipes;
    } else {
      final users = await supabase.from('users').select();
      final follows = await supabase.from('follows').select('following_id');

      for (var user in users) {
        user['follower_count'] = follows.where((f) => f['following_id'] == user['id']).length;
      }
      users.sort((a, b) => b['follower_count'].compareTo(a['follower_count']));
      return users;
    }
  }

  Widget _buildRankBadge(int rank) {
    Color color = rank == 1
        ? Colors.amber
        : (rank == 2 ? Colors.grey : (rank == 3 ? Colors.brown : Colors.orange[200]!));

    return CircleAvatar(
        backgroundColor: color,
        radius: 15,
        child: Text("$rank", style: const TextStyle(color: Colors.white, fontSize: 12))
    );
  }
}