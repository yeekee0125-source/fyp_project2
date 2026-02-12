import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ⚠️ Your API Key
  static const String _apiKey = 'AIzaSyC2Vi3yyF0QTLlctItv7mFbyLm4Xo_Favk';

  Future<String> generateRecipe(String ingredients) async {
    // ✅ 1. Use the correct URL for Gemini Pro
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$_apiKey',
    );

    // ✅ 2. Construct the prompt
    final prompt = 'Suggest a cooking recipe using the following ingredients: $ingredients. '
        'Include Recipe name, Ingredients list, and Cooking steps. Keep it simple.';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": prompt}]
          }]
        }),
      );

      if (response.statusCode != 200) {
        // Print the real error to the console
        print("API Error: ${response.body}");
        throw Exception('Gemini API Error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['candidates'] != null &&
          data['candidates'].isNotEmpty &&
          data['candidates'][0]['content'] != null) {
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "No recipe returned. Try different ingredients.";
      }

    } catch (e) {
      print("🔴 GEMINI ERROR: $e");
      return 'Failed to generate recipe. Check console for details.';
    }
  }
}