import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AICoachService {
  final _client = Supabase.instance.client;
  final _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: 'AIzaSyBphkvqSAw-6s2az2H3cxOiBrSo7n6R2bw',
  );

  Future<List<Map<String, dynamic>>> loadChatHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('feedback')
          .select('chat_history')
          .eq('user_id', user.id)
          .eq('reason', 'AI Nutrition Coaching Session')
          .maybeSingle();

      if (response != null && response['chat_history'] != null) {
        return List<Map<String, dynamic>>.from(response['chat_history']);
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
    return [];
  }

  // Save the conversation to the feedback table (Upsert)
  Future<void> saveChatToDatabase(List<Map<String, dynamic>> messages) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('feedback').upsert({
        'user_id': user.id,
        'reason': 'AI Nutrition Coaching Session',
        'status': 'Resolved', // AI sessions are auto-resolved
        'chat_history': messages,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, reason');
    } catch (e) {
      debugPrint("Error saving chat: $e");
    }
  }

  Future<String> getCoachResponse(String userMessage) async {
    final user = _client.auth.currentUser;
    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      final scanData = await _client
          .from('calorie_scans')
          .select('detected_dish, estimated_calorie')
          .eq('user_id', user!.id)
          .gte('scanned_at', today);

      final userData = await _client
          .from('users')
          .select('name, preferences')
          .eq('id', user.id)
          .single();

      String name = userData['name'] ?? 'User';
      String prefs = userData['preferences'] ?? 'None';
      String mealSummary = scanData.isEmpty
          ? "No meals scanned today."
          : scanData.map((s) => "${s['detected_dish']} (${s['estimated_calorie']} kcal)").join(", ");

      final prompt = """
        You are 'Kitchen Buddy Coach'. 
        User: $name. Prefs: $prefs.
        Today's History: $mealSummary.
        Question: "$userMessage"
        Instruction: Provide short, professional nutritional advice (max 2 sentences).
      """;

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "I'm processing your request...";
    } catch (e) {
      return "Unable to access data: $e";
    }
  }
}