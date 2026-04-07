import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {

  String get _apiKey {
    // If the key is missing from the .env file, it returns an empty string to prevent crashes
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  Future<String> generateRecipe(String ingredients, List<String> userPreferences) async {
    try {
      // 2. Check if the key actually exists
      if (_apiKey.isEmpty) {
        return "Error: API Key is missing.";
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey,
      );

      String dietString = userPreferences.isEmpty
          ? ""
          : "IMPORTANT: The recipe must be ${userPreferences.join(', ')}.";

      final prompt = 'Suggest a cooking recipe using these ingredients: $ingredients. '
          '$dietString '
          'Include Recipe name, Ingredients list, and Cooking steps. Keep it simple.';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ?? "No recipe found. Try again.";

    } catch (e) {
      print("🔴 GEMINI SDK ERROR: $e");
      return "Failed to generate recipe. Please check your internet connection.";
    }
  }
}