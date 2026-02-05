import 'package:flutter/material.dart';
import 'dart:io';
import 'database_service.dart';
import 'recipe_model.dart';
import 'package:image_picker/image_picker.dart';

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
  final _categoryCtrl = TextEditingController();
  final _servingCtrl = TextEditingController();

  final db = DatabaseService();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers if updating existing recipe
    if (widget.recipe != null) {
      _titleCtrl.text = widget.recipe!.title;
      _ingredientsCtrl.text = widget.recipe!.ingredients;
      _stepsCtrl.text = widget.recipe!.steps;
      _categoryCtrl.text = widget.recipe!.category;
      _servingCtrl.text = widget.recipe!.servings.toString();
      if (widget.recipe!.imagePath != null) {
        _selectedImage = File(widget.recipe!.imagePath!);
      }
    }
  }

  void _saveRecipe() async {

    String? finalImagePath = widget.recipe?.imagePath;
    // 1. If a new image was picked, upload it to Supabase Storage first
    if (_selectedImage != null && (_selectedImage?.path != widget.recipe?.imagePath)) {
      // Generate/Use ID for the image path
      final tempId = widget.recipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Upload to Supabase and get the Public URL
      final cloudUrl = await db.uploadRecipeImage(_selectedImage!, tempId);
      if (cloudUrl != null) {
        finalImagePath = cloudUrl;
      }
    }

    final recipe = RecipeModel(
      // Keep the old ID if updating, or create a new one for a new recipe
      id: widget.recipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      ingredients: _ingredientsCtrl.text.trim(),
      steps: _stepsCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      servings: int.tryParse(_servingCtrl.text) ?? 1,
      createdOn: widget.recipe?.createdOn ?? DateTime.now(),
      imagePath: finalImagePath,
    );

    if (widget.recipe == null) {
      await db.addRecipe(recipe);
    } else {
      await db.updateRecipe(recipe);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF3CC),
        elevation: 0,
        title: const Text(
          'Create your own recipe',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image Placeholder
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black),
                  image: _selectedImage != null
                      ? DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Icon(Icons.image_outlined, size: 50)
                    : null,
              ),
            ),

            _buildTextField(
              label: 'Recipe Title',
              controller: _titleCtrl,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              label: 'Ingredients',
              controller: _ingredientsCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              label: 'Instructions',
              controller: _stepsCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            _buildTextField(
              label: 'Category',
              controller: _categoryCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            _buildTextField(
              label: 'Serving Size',
              controller: _servingCtrl,
            ),
            const SizedBox(height: 15),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(
                  text: 'Add Recipe',
                  onTap: _saveRecipe,
                ),

                _buildButton(
                  text: 'Cancel',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Reusable Widgets
  // =========================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFFE5A5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding:
        const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
