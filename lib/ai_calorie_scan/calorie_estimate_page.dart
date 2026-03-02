import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalorieEstimationPage extends StatefulWidget {
  const CalorieEstimationPage({super.key});

  @override
  State<CalorieEstimationPage> createState() => _CalorieEstimationPageState();
}

class _CalorieEstimationPageState extends State<CalorieEstimationPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  late final GenerativeModel _model;

  /// The Gemini API Key used for calorie estimation.
  ///
  /// IMPORTANT: This key is temporarily hardcoded for the Final Year Project
  /// submission. This approach is chosen to facilitate ease of testing for
  /// examiners. Secure environment variables should be used for deployment.
  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: '',//paste this api key inside the string: AIzaSyDuS2u7wp9d5_kPyJ4yuPu61xvPnw4fGeM
    );
  }

  // State Variables
  File? _selectedImage;
  bool _isCameraSource = true;
  String _selectedPortion = 'Medium';
  final List<String> _addons = [];
  bool _isAnalyzing = false;

  // Result Variables
  String? _resultDish;
  int? _resultCalories;

  final TextEditingController _dishNameController = TextEditingController();

  // --- Logic Functions ---

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isCameraSource = (source == ImageSource.camera);
        _resultCalories = null;
        _resultDish = null;
      });
    }
  }

  Future<void> _estimateCalories() async {
    if (_selectedImage == null && _dishNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a photo or describe your dish.")),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      String userDescription = _dishNameController.text.trim();
      String promptText = "Estimate calories for this dish. ";
      if (userDescription.isNotEmpty) promptText += "Description: $userDescription. ";
      promptText += "Portion size: $_selectedPortion. ";
      if (_addons.isNotEmpty) promptText += "Add-ons: ${_addons.join(', ')}. ";
      promptText += "Respond exactly in this format: Dish Name | Calories (Number).";

      final List<Part> parts = [TextPart(promptText)];

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      final response = await _model.generateContent([Content.multi(parts)]);
      final responseText = response.text ?? "";

      if (responseText.contains('|')) {
        final data = responseText.split('|');
        final dish = data[0].trim();
        final kcal = int.tryParse(data[1].replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0;

        await _saveToSupabase(dish, kcal, _selectedPortion);

        if (mounted) {
          setState(() {
            _resultDish = dish;
            _resultCalories = kcal;
          });
        }
      }
    } catch (e) {
      debugPrint("Estimation Error: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveToSupabase(String dish, int kcal, String portion) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    String? finalImageUrl;

    if (_selectedImage != null) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'scans/${user.id}/$fileName';
        await supabase.storage.from('calorie_scans').upload(path, _selectedImage!);
        finalImageUrl = supabase.storage.from('calorie_scans').getPublicUrl(path);
      } catch (e) {
        debugPrint("Upload failed: $e");
      }
    }

    try {
      await supabase.from('calorie_scans').insert({
        'user_id': user.id,
        'detected_dish': dish,
        'estimated_calorie': kcal,
        'image_url': finalImageUrl,
        'portion_size': portion,
      });
    } catch (e) {
      debugPrint("Database Save Error: $e");
    }
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Calorie Estimation",
            style: TextStyle(color: Color(0xFF8D7A66), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageDisplayArea(),
            const SizedBox(height: 30),
            if (_isAnalyzing) _buildLoadingView()
            else if (_resultCalories != null) _buildResultView()
            else _buildDefaultInputForm(),
            const SizedBox(height: 40),
            if (!_isAnalyzing && _resultCalories == null) _buildEstimateButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplayArea() {
    return Row(
      children: [
        Expanded(child: _selectedImage != null && _isCameraSource ? _buildImagePreview() : _imageActionCard("Take Photo", Icons.camera_alt_outlined, ImageSource.camera)),
        const SizedBox(width: 15),
        Expanded(child: _selectedImage != null && !_isCameraSource ? _buildImagePreview() : _imageActionCard("Upload Photo", Icons.upload_outlined, ImageSource.gallery)),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover)),
        Positioned(top: 5, right: 5, child: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.7), child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => setState(() { _selectedImage = null; _resultCalories = null; })))),
      ],
    );
  }

  Widget _imageActionCard(String label, IconData icon, ImageSource source) {
    return InkWell(
      onTap: () => _pickImage(source),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: 150,
        decoration: BoxDecoration(color: const Color(0xFFE5E2D0), borderRadius: BorderRadius.circular(25)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 35, color: Colors.grey[600]), const SizedBox(height: 10), Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500))]),
      ),
    );
  }

  Widget _buildDefaultInputForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Prefer to describe in text?", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 5),
        const Text("Dish Name", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8D7A66))),
        _buildTextField("e.g. Nasi Lemak"),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Portion Size", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8D7A66))),
            IconButton(onPressed: _showPortionGuide, icon: const Icon(Icons.help_outline, color: Colors.orange)),
          ],
        ),
        _buildDropdownField(),
        const SizedBox(height: 20),
        const Text("Optional Add-ons", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8D7A66))),
        _buildAddOnSection(),
      ],
    );
  }

  void _showPortionGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Portion Guide"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Text("🤲"), title: Text("Small"), subtitle: Text("Cupped hand (0.5 cup)")),
            ListTile(leading: Text("✊"), title: Text("Medium"), subtitle: Text("Fist size (1 cup)")),
            ListTile(leading: Text("✊✊"), title: Text("Large"), subtitle: Text("Two fists (2 cups)")),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(color: const Color(0xFFE5E2D0).withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
      child: TextField(controller: _dishNameController, decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), border: InputBorder.none)),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: const Color(0xFFE5E2D0).withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPortion,
          isExpanded: true,
          items: ['Small', 'Medium', 'Large'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: (val) => setState(() => _selectedPortion = val!),
        ),
      ),
    );
  }

  Widget _buildAddOnSection() {
    return Column(
      children: [
        GestureDetector(onTap: () => _showAddonDialog(), child: Container(margin: const EdgeInsets.only(top: 8), width: double.infinity, height: 50, decoration: BoxDecoration(color: const Color(0xFFE5E2D0).withOpacity(0.6), borderRadius: BorderRadius.circular(30)), child: const Icon(Icons.add, color: Colors.grey, size: 30))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: _addons.map((addon) => Chip(label: Text(addon), onDeleted: () => setState(() => _addons.remove(addon)))).toList()),
      ],
    );
  }

  void _showAddonDialog() {
    TextEditingController addonController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Add extra items"), content: TextField(controller: addonController, autofocus: true, decoration: const InputDecoration(hintText: "e.g. 1 Fried Egg")), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), TextButton(onPressed: () { if (addonController.text.isNotEmpty) setState(() => _addons.add(addonController.text)); Navigator.pop(context); }, child: const Text("Add"))]));
  }

  Widget _buildLoadingView() {
    return const Center(child: Column(children: [SizedBox(height: 50), CircularProgressIndicator(color: Colors.orange), SizedBox(height: 20), Text("AI is analyzing...")]));
  }

  Widget _buildResultView() {
    return Center(
      child: Column(
        children: [
          Text(_resultDish ?? "", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF8D7A66))),
          const SizedBox(height: 5),
          Text("Portion: $_selectedPortion", style: const TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic)),
          const SizedBox(height: 15),
          Container(width: 220, padding: const EdgeInsets.symmetric(vertical: 30), decoration: BoxDecoration(border: Border.all(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(25)), child: Center(child: Text("$_resultCalories kcal", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.orange)))),
          const SizedBox(height: 20),
          TextButton(onPressed: () => setState(() { _resultCalories = null; _resultDish = null; _selectedImage = null; _dishNameController.clear(); _addons.clear(); }), child: const Text("Scan Another Dish", style: TextStyle(color: Colors.grey, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildEstimateButton() {
    return InkWell(onTap: _isAnalyzing ? null : _estimateCalories, child: Container(width: double.infinity, height: 55, decoration: BoxDecoration(color: const Color(0xFFFFA756), borderRadius: BorderRadius.circular(30)), child: Center(child: Text(_isAnalyzing ? "Processing..." : "ESTIMATE", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))));
  }
}