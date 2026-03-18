import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = '';

  Future<String> generateRecipe(String ingredients, List<String> userPreferences) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
      );

      // 1. Format the preferences into a sentence for the AI
      // e.g., "The recipe must be Halal, Spicy."
      String dietString = userPreferences.isEmpty
          ? ""
          : "IMPORTANT: The recipe must be ${userPreferences.join(', ')}.";

      // 2. Create the smart prompt
      final prompt = 'Suggest a cooking recipe using these ingredients: $ingredients. '
          '$dietString ' //The preferences are injected here
          'Include Recipe name, Ingredients list, and Cooking steps. Keep it simple.';

      final content = [Content.text(prompt)];

      // 3. Generate content
      final response = await model.generateContent(content);

      // 4. Return the result
      return response.text ?? "No recipe found. Try again.";

    } catch (e) {
      print("🔴 GEMINI SDK ERROR: $e");
      return "Failed to generate recipe. Please check your internet connection.";
    }
  }
}