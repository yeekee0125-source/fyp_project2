import 'package:flutter/material.dart';
import 'ai_recipe_gemini.dart'; // Your GeminiService class

class AIRecipePage extends StatefulWidget {
  const AIRecipePage({super.key});

  @override
  State<AIRecipePage> createState() => _AIRecipePageState();
}

class _AIRecipePageState extends State<AIRecipePage> {
  final TextEditingController _ingredientCtrl = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  String _recipeResult = '';
  bool _isLoading = false;

  // Call Gemini API
  Future<void> _generateRecipe() async {
    final ingredients = _ingredientCtrl.text.trim();
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some ingredients!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _geminiService.generateRecipe(ingredients);
      setState(() => _recipeResult = result);
    } catch (e) {
      setState(() => _recipeResult = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ingredientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C2),
      appBar: AppBar(
        title: const Text('AI Recipe Recommendation'),
        backgroundColor: const Color(0xFFFFE59D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Input field
            TextField(
              controller: _ingredientCtrl,
              decoration: const InputDecoration(
                labelText: 'Enter ingredients (e.g. chicken, rice)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.kitchen),
              ),
            ),
            const SizedBox(height: 20),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Generate Recipe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Result
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: _recipeResult.isEmpty
                    ? const Center(
                  child: Text(
                    'Your recipe will appear here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : SingleChildScrollView(
                  child: Text(
                    _recipeResult,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
