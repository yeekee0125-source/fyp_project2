import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipe_model.dart';
import '../../services/search_service.dart';
import '../../widgets/recipe_card.dart';


class SearchDiscoveryScreen extends StatefulWidget {
  const SearchDiscoveryScreen({super.key});

  @override
  State<SearchDiscoveryScreen> createState() => _SearchDiscoveryScreenState();
}

class _SearchDiscoveryScreenState extends State<SearchDiscoveryScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchCtrl = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  List<String> _recentSearches = [];
  List<RecipeModel> _results = [];
  bool _isSearching = false;
  bool _isFilterVisible = false;

  // Linked to your hardcoded categories
  final List<String> _filterCategories = [
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

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  // ● Load history from Supabase
  Future<void> _loadSearchHistory() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('search_history')
        .select('query')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(10);

    setState(() {
      _recentSearches = List<String>.from(data.map((item) => item['query']));
    });
  }

  // ● Save history to Supabase (Upsert logic)
  Future<void> _saveSearchHistory(String query) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('search_history').upsert({
      'user_id': user.id,
      'query': query,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, query');

    _loadSearchHistory(); // Refresh the list
  }

  void _onSearch(String value) async {
    if (value.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _isFilterVisible = false;
    });

    await _saveSearchHistory(value);

    final data = await _searchService.searchRecipes(keyword: value);
    setState(() {
      _results = data;
      _isSearching = false;
    });
  }

  void _applyFilter(String filter) async {
    setState(() {
      _isSearching = true;
      _isFilterVisible = false;
    });

    List<RecipeModel> filteredData;

    if (filter == 'All Categories') {
      // Show everything
      filteredData = await _searchService.searchRecipes(category: null);
    } else if (filter == 'Other') {
      // Logic: Find recipes where the category is NOT in your standard list
      // Note: This requires a specific query in your SearchService
      filteredData = await _searchService.getCustomCategories(excludeList: _filterCategories);
    } else {
      // Standard category search (Western, Japanese, etc.)
      filteredData = await _searchService.searchRecipes(category: filter);
    }

    setState(() {
      _results = filteredData;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Search & Discover',
            style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_isFilterVisible) setState(() => _isFilterVisible = false);
            },
            child: Column(
              children: [
                _buildSearchHeader(),
                Expanded(
                  child: _isSearching
                      ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                      : _results.isEmpty
                      ? SingleChildScrollView(child: _buildRecentSection())
                      : _buildResultsList(),
                ),
              ],
            ),
          ),
          if (_isFilterVisible) _buildSideFilterPanel(),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchCtrl,
        onSubmitted: _onSearch,
        decoration: InputDecoration(
          hintText: 'Search recipe or tutorials',
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, color: Colors.orange),
            onPressed: () => setState(() => _isFilterVisible = !_isFilterVisible),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent searches',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown)),
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final user = supabase.auth.currentUser;
                    if (user != null) {
                      await supabase.from('search_history').delete().eq('user_id', user.id);
                      setState(() => _recentSearches = []);
                    }
                  },
                  child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((tag) => ActionChip(
              backgroundColor: Colors.white,
              label: Text(tag, style: const TextStyle(color: Colors.orange)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                _searchCtrl.text = tag;
                _onSearch(tag);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: _results.length,
      itemBuilder: (context, index) => RecipeCard(recipe: _results[index]),
    );
  }

  Widget _buildSideFilterPanel() {
    return Positioned(
      top: 0,
      right: 16,
      child: Container(
        width: 180,
        // Set a max height so it doesn't go off-screen with many categories
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)
          ],
        ),
        child: SingleChildScrollView( // Allows scrolling if the list is long
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _filterCategories.map((filter) {
              return InkWell(
                onTap: () => _applyFilter(filter),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Text(
                    filter,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}