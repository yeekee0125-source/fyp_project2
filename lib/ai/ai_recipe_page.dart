import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for Clipboard
import 'ai_recipe_gemini.dart';
import '../../services/database_service.dart'; // 🔥 Make sure this import is correct

class AIRecipePage extends StatefulWidget {
  const AIRecipePage({super.key});

  @override
  State<AIRecipePage> createState() => _AIRecipePageState();
}

class _AIRecipePageState extends State<AIRecipePage> {
  final TextEditingController _ingredientController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final DatabaseService _db = DatabaseService(); // 🔥 Database connection

  String _result = "";
  bool _isLoading = false;

  // 🔥 1. DEFINE PREFERENCES
  final List<String> _dietaryOptions = ["Halal", "Vegetarian", "Healthy", "Spicy", "Quick", "Breakfast"];
  final List<String> _selectedPreferences = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // 🔥 Load saved settings when page starts
  }

  // Load from Supabase
  Future<void> _loadPreferences() async {
    final savedPrefs = await _db.getUserPreferences();
    if (mounted) {
      setState(() {
        _selectedPreferences.addAll(savedPrefs);
      });
    }
  }

  Future<void> _generateRecipe() async {
    final ingredients = _ingredientController.text.trim();

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter some ingredients! 🥕🥩"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _result = ""; // Clear previous result
    });

    try {
      // 🔥 2. PASS PREFERENCES TO GEMINI
      // Note: Ensure you updated GeminiService to accept this 2nd argument!
      final recipe = await _geminiService.generateRecipe(ingredients, _selectedPreferences);
      setState(() => _result = recipe);
    } catch (e) {
      setState(() => _result = "Error: Could not generate recipe. $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Copy to Clipboard Function
  void _copyToClipboard() {
    if (_result.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Recipe copied to clipboard! 📋"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6), // KitchenBuddy Beige Theme
      appBar: AppBar(
        title: const Text(
          "AI Chef",
          style: TextStyle(
              color: Color(0xFFE67E22),
              fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Tap anywhere to close keyboard
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER TEXT
              const Text(
                "What's in your fridge?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Enter ingredients and let AI create a recipe for you.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 15),

              // 🔥 3. PREFERENCE CHIPS UI
              const Text(
                "Dietary Preferences:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0, // Adds space between lines
                children: _dietaryOptions.map((option) {
                  final isSelected = _selectedPreferences.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    selectedColor: Colors.orange.withOpacity(0.3),
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.deepOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.deepOrange : Colors.brown,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? Colors.orange : Colors.transparent),
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedPreferences.add(option);
                        } else {
                          _selectedPreferences.remove(option);
                        }
                      });
                      // 🔥 Auto-save whenever they change a chip
                      _db.saveUserPreferences(_selectedPreferences);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 2. INPUT FIELD (Styled Box)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _ingredientController,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.brown),
                  decoration: const InputDecoration(
                    hintText: "e.g. Chicken, Rice, Soy Sauce...",
                    hintStyle: TextStyle(color: Colors.black26),
                    prefixIcon: Icon(Icons.kitchen, color: Colors.orange),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. GENERATE BUTTON (Gradient Pill)
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      ),
                      SizedBox(width: 15),
                      Text("Chef is thinking...", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Generate Recipe",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 4. RESULT AREA
              Expanded(
                child: _result.isEmpty
                    ? _buildEmptyState()
                    : _buildResultCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Show this when no recipe is generated yet
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 80, color: Colors.orange.withOpacity(0.3)),
          const SizedBox(height: 15),
          Text(
            "No recipe yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.brown.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Show this when the recipe is ready
  Widget _buildResultCard() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25), // Space for the copy button
                SelectableText(
                  _result,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Floating Copy Button (Top Right of Card)
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: const Icon(Icons.copy, color: Colors.orange),
            tooltip: "Copy Recipe",
            onPressed: _copyToClipboard,
          ),
        ),
      ],
    );
  }
}