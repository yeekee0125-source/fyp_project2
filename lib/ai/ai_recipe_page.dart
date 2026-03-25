import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_recipe_gemini.dart';
import '../../services/database_service.dart';
import '../../models/recipe_model.dart'; // Make sure this path is correct
//import '../../ai/pantry_algorithm.dart'; // Uncomment and fix this import to wherever your PantryAlgorithm is!

class AIRecipePage extends StatefulWidget {
  const AIRecipePage({super.key});

  @override
  State<AIRecipePage> createState() => _AIRecipePageState();
}

class _AIRecipePageState extends State<AIRecipePage> {
  final DatabaseService _db = DatabaseService();

  // ==========================================
  // 🧠 1. SMART PANTRY STATE VARIABLES
  // ==========================================
  final TextEditingController _pantryInputCtrl = TextEditingController();
  // final PantryAlgorithm _pantryAlgo = PantryAlgorithm(); // Uncomment this when you fix the import!
  final List<String> _myPantryIngredients = [];
  List<Map<String, dynamic>> _pantryResults = [];
  bool _isPantryLoading = false;
  bool _hasSearchedPantry = false;

  // ==========================================
  // 🤖 2. AI CHEF STATE VARIABLES
  // ==========================================
  final TextEditingController _ingredientController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  String _result = "";
  bool _isLoading = false;

  final List<String> _dietaryOptions = [
    "Halal", "Vegetarian", "Vegan", "Gluten-Free",
    "Keto", "High Protein", "Healthy", "Spicy", "Quick", "Breakfast"
  ];
  final List<String> _selectedPreferences = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final savedPrefs = await _db.getUserPreferences();
    if (mounted) {
      setState(() {
        _selectedPreferences.addAll(savedPrefs);
      });
    }
  }

  @override
  void dispose() {
    _pantryInputCtrl.dispose();
    _ingredientController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🧠 3. SMART PANTRY LOGIC (The Smart Parser)
  // ==========================================
  Future<void> _searchPantry() async {
    String currentText = _pantryInputCtrl.text.trim();

    // SMART PARSER: Automatically split by commas
    if (currentText.isNotEmpty) {
      List<String> newItems = currentText.split(',');

      setState(() {
        for (String item in newItems) {
          String cleanItem = item.trim();
          if (cleanItem.isNotEmpty && !_myPantryIngredients.contains(cleanItem)) {
            _myPantryIngredients.add(cleanItem);
          }
        }
        _pantryInputCtrl.clear();
      });
    }

    if (_myPantryIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please type an ingredient first! 🥕"), backgroundColor: Colors.red),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isPantryLoading = true);

    // 🔥 Make sure your PantryAlgorithm class is imported at the top!
    // final results = await _pantryAlgo.findMatchingRecipes(_myPantryIngredients);

    setState(() {
      // _pantryResults = results; // Uncomment this when your algorithm is linked
      _isPantryLoading = false;
      _hasSearchedPantry = true;
    });
  }

  // ==========================================
  // 🤖 4. AI CHEF LOGIC
  // ==========================================
  Future<void> _generateRecipe() async {
    final ingredients = _ingredientController.text.trim();

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter some ingredients! 🥕🥩"), backgroundColor: Colors.red),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _result = "";
    });

    try {
      final recipe = await _geminiService.generateRecipe(ingredients, _selectedPreferences);
      setState(() => _result = recipe);
    } catch (e) {
      setState(() => _result = "Error: Could not generate recipe. $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_result.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe copied to clipboard! 📋"), backgroundColor: Colors.green),
      );
    }
  }

  // ==========================================
  // 📱 5. UI BUILDER (The Tabs)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // 🔥 We use DefaultTabController to bring back the Tabs!
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBE6),
        appBar: AppBar(
          title: const Text(
            "Smart Kitchen Hub",
            style: TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.brown),
          bottom: const TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(icon: Icon(Icons.kitchen), text: "Smart Pantry"),
              Tab(icon: Icon(Icons.auto_awesome), text: "AI Chef"),
            ],
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: TabBarView(
            children: [
              _buildPantryTab(), // Tab 1
              _buildAIChefTab(), // Tab 2
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🧠 TAB 1: SMART PANTRY UI
  // ==========================================
  Widget _buildPantryTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Search Database by Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
          const Text("Type comma-separated ingredients (e.g. Egg, Rice) and hit search.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),

          // Input Box
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))]),
            child: TextField(
              controller: _pantryInputCtrl,
              decoration: InputDecoration(
                hintText: "What's in your fridge?",
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_circle_right, color: Colors.orange, size: 30),
                  onPressed: _searchPantry,
                ),
              ),
              onSubmitted: (_) => _searchPantry(),
            ),
          ),
          const SizedBox(height: 10),

          // Chips Display
          Wrap(
            spacing: 8,
            children: _myPantryIngredients.map((ing) => Chip(
              label: Text(ing),
              backgroundColor: Colors.orange.withOpacity(0.2),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() {
                _myPantryIngredients.remove(ing);
                _hasSearchedPantry = false;
              }),
            )).toList(),
          ),
          const SizedBox(height: 15),

          // Results List
          Expanded(
            child: _isPantryLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : _hasSearchedPantry && _pantryResults.isEmpty
                ? const Center(child: Text("No exact matches found in database. Try the AI Chef!"))
                : ListView.builder(
              itemCount: _pantryResults.length,
              itemBuilder: (context, index) {
                final data = _pantryResults[index];
                final RecipeModel recipe = data['recipe'];
                final double percentage = data['percentage'];
                Color matchColor = percentage >= 0.7 ? Colors.green : (percentage >= 0.4 ? Colors.orange : Colors.red);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewRecipePage(recipe: recipe))),
                    title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        LinearProgressIndicator(value: percentage, color: matchColor, backgroundColor: Colors.grey[200]),
                        const SizedBox(height: 5),
                        Text("You have ${data['match_count']} of ${data['total_needed']} ingredients", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Text("${(percentage * 100).toInt()}%", style: TextStyle(color: matchColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🤖 TAB 2: AI CHEF UI
  // ==========================================
  Widget _buildAIChefTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Generate New Recipe", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
          const Text("Let AI invent a meal based on your diet.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 15),

          // PREFERENCE CHIPS UI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _dietaryOptions.map((option) {
                final isSelected = _selectedPreferences.contains(option);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
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
                        selected ? _selectedPreferences.add(option) : _selectedPreferences.remove(option);
                      });
                      _db.saveUserPreferences(_selectedPreferences);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // INPUT FIELD
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))]),
            child: TextField(
              controller: _ingredientController,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: "e.g. Chicken, Rice, Soy Sauce...",
                prefixIcon: Icon(Icons.kitchen, color: Colors.orange),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // GENERATE BUTTON
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _generateRecipe,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: _isLoading
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 15), Text("Chef is thinking...", style: TextStyle(color: Colors.white, fontSize: 16))])
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_awesome, color: Colors.white), SizedBox(width: 10), Text("Generate Recipe", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))]),
            ),
          ),
          const SizedBox(height: 25),

          // RESULT AREA
          Expanded(
            child: _result.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.menu_book_rounded, size: 80, color: Colors.orange.withOpacity(0.3)), const SizedBox(height: 15), Text("No recipe yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.brown.withOpacity(0.5)))]))
                : Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))]),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
                    child: SingleChildScrollView(child: _formatRecipe(_result)),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: Material(
                      color: Colors.orange, shape: const CircleBorder(), elevation: 4,
                      child: IconButton(icon: const Icon(Icons.copy, color: Colors.white), onPressed: _copyToClipboard),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Text formatting helper
  Widget _formatRecipe(String text) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.toLowerCase().contains("ingredients")) return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text("🧂 Ingredients", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)));
        if (line.toLowerCase().contains("steps") || line.toLowerCase().contains("method")) return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text("👨‍🍳 Cooking Steps", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)));
        if (line.trim().isEmpty) return const SizedBox(height: 8);
        if (!line.startsWith("-") && !line.contains(":") && line.length < 40) return Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(line, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange)));
        return Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(line, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87)));
      }).toList(),
    );
  }
}