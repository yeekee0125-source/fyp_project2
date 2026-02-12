import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/recipe_model.dart';
import 'package:image_picker/image_picker.dart';
import 'database_service.dart';

class AddRecipePage extends StatefulWidget {
  final RecipeModel? recipe; // If this exists, we are UPDATING
  const AddRecipePage({super.key, this.recipe});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _titleCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();
  final _servingCtrl = TextEditingController();
  final _cookingTimeCtrl = TextEditingController();

  // NEW: Category Logic
  final _otherCategoryCtrl = TextEditingController();
  String? _selectedCategory;
  bool _isOtherSelected = false;
  final List<String> _hardcodedCategories = [
    'All Categories',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Western',
    'Japanese',
    'Korean',
    'Chinese',
    'Malay',
    'Dessert',
    'Healthy',
    'Vegan',
    'Seafood',
    'Other'
  ];

  String? _selectedSkillLevel;

  final db = DatabaseService();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _titleCtrl.text = widget.recipe!.title;
      _ingredientsCtrl.text = widget.recipe!.ingredients;
      _stepsCtrl.text = widget.recipe!.steps;
      _servingCtrl.text = widget.recipe!.servings.toString();
      _cookingTimeCtrl.text = widget.recipe!.cookingTime.toString();
      _selectedSkillLevel = widget.recipe!.skillLevel;

      // Handle Category pre-filling
      if (widget.recipe!.category.isNotEmpty) {
        String primaryCat = widget.recipe!.category.first;
        if (_hardcodedCategories.contains(primaryCat)) {
          _selectedCategory = primaryCat;
        } else {
          _selectedCategory = 'Other';
          _isOtherSelected = true;
          _otherCategoryCtrl.text = primaryCat;
        }
      }
    }
  }

  void _saveRecipe() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe title'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      String? finalImagePath = widget.recipe?.imagePath;

      if (_selectedImage != null) {
        final tempId = widget.recipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        final cloudUrl = await db.uploadRecipeImage(_selectedImage!, tempId);
        if (cloudUrl != null) finalImagePath = cloudUrl;
      }

      // Logic to get Category String from Dropdown or "Other" text field
      String categoryValue = _isOtherSelected
          ? _otherCategoryCtrl.text.trim()
          : (_selectedCategory ?? 'Uncategorized');

      // Convert to List<String> to keep teammate's model happy
      List<String> categories = [categoryValue].where((e) => e.isNotEmpty).toList();

      final String currentUid = db.supabase.auth.currentUser?.id ?? '';

      final recipe = RecipeModel(
        id: widget.recipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        ingredients: _ingredientsCtrl.text.trim(),
        steps: _stepsCtrl.text.trim(),
        category: categories,
        servings: int.tryParse(_servingCtrl.text) ?? 1,
        imagePath: finalImagePath,
        createdOn: widget.recipe?.createdOn ?? DateTime.now(),
        cookingTime: int.tryParse(_cookingTimeCtrl.text) ?? 0,
        skillLevel: _selectedSkillLevel ?? 'Beginner',
        totalViews: widget.recipe?.totalViews ?? 0,
        userId: widget.recipe?.userId ?? currentUid,

      );

      if (widget.recipe == null) {
        await db.addRecipe(recipe);
      } else {
        await db.updateRecipe(recipe);
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.recipe == null ? 'Recipe added successfully! 🍳' : 'Recipe updated! ✨'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pop(context, true);

    } catch (e) {
      Navigator.pop(context);
      log('Error saving recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF3CC),
        elevation: 0,
        title: Text(widget.recipe == null ? 'Create your own recipe' : 'Edit Recipe',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120, width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5A5),
                  borderRadius: BorderRadius.circular(15),
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      : (widget.recipe?.imagePath != null
                      ? DecorationImage(image: NetworkImage(widget.recipe!.imagePath!), fit: BoxFit.cover)
                      : null),
                ),
                child: (_selectedImage == null && widget.recipe?.imagePath == null)
                    ? const Icon(Icons.image_outlined, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            _buildTextField(label: 'Recipe Title', controller: _titleCtrl),
            const SizedBox(height: 15),

            // NEW Category Selection Logic
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Category", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    filled: true, fillColor: const Color(0xFFFFE5A5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  ),
                  items: _hardcodedCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                      _isOtherSelected = (val == 'Other');
                    });
                  },
                ),
              ],
            ),
            if (_isOtherSelected) ...[
              const SizedBox(height: 10),
              _buildTextField(label: 'Enter Custom Category', controller: _otherCategoryCtrl),
            ],

            const SizedBox(height: 15),
            _buildTextField(label: 'Ingredients', controller: _ingredientsCtrl, maxLines: 3),
            const SizedBox(height: 15),
            _buildTextField(label: 'Instructions', controller: _stepsCtrl, maxLines: 3),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(child: _buildTextField(label: 'Time (mins)', controller: _cookingTimeCtrl)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Skill Level", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: _selectedSkillLevel,
                        items: ['Beginner', 'Intermediate', 'Expert']
                            .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedSkillLevel = val),
                        decoration: InputDecoration(
                          filled: true, fillColor: const Color(0xFFFFE5A5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(label: 'Serving Size', controller: _servingCtrl),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(text: widget.recipe == null ? 'Add Recipe' : 'Update', onTap: _saveRecipe),
                _buildButton(text: 'Cancel', onTap: () => Navigator.pop(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Same Reusable Widgets...
  Widget _buildTextField({required String label, required TextEditingController controller, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFFFE5A5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({required String text, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}