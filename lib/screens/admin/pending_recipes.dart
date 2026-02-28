import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/recipe_model.dart';

class AdminPendingRecipes extends StatefulWidget {
  const AdminPendingRecipes({super.key});

  @override
  State<AdminPendingRecipes> createState() => _AdminPendingRecipesState();
}

class _AdminPendingRecipesState extends State<AdminPendingRecipes> {
  final db = DatabaseService();
  List<RecipeModel> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingRecipes();
  }

  // 1. Fetch data once when the page loads
  Future<void> _fetchPendingRecipes() async {
    try {
      final recipes = await db.fetchPendingRecipes();
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. Handle the button click with an immediate UI update
  void _handleAction(RecipeModel recipe, bool isApprove) async {
    // Optimistic UI Update: Instantly remove it from the screen
    setState(() {
      _recipes.removeWhere((r) => r.id == recipe.id);
    });

    try {
      // Update the database in the background
      if (isApprove) {
        await db.approveRecipe(recipe.id);
      } else {
        await db.rejectRecipe(recipe.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApprove ? 'Recipe Approved' : 'Recipe Rejected'),
            backgroundColor: isApprove ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // If the database fails, re-fetch the list to correct the UI
      _fetchPendingRecipes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Recipes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
          ? const Center(child: Text('No pending recipes'))
          : ListView.builder(
        itemCount: _recipes.length,
        itemBuilder: (_, i) {
          final r = _recipes[i];
          return Card(
            child: ListTile(
              title: Text(r.title),
              subtitle: Text(r.category.join(', ')), // jx
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _handleAction(r, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _handleAction(r, false),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}