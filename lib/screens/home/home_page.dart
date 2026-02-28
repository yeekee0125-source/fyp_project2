import 'package:flutter/material.dart';
import 'package:fyp_project2/screens/home/ranking_results_page.dart';
import 'package:fyp_project2/screens/home/search_screen.dart';
import 'package:fyp_project2/models/recipe_model.dart';
import 'package:fyp_project2/models/video_model.dart';
import 'package:fyp_project2/services/database_service.dart';
import 'package:fyp_project2/services/search_service.dart';
import 'package:fyp_project2/services/video_service.dart';
import '../auth/login.dart';
import '../recipe/view_recipe.dart';
import '../video/video_player_page.dart';
import 'package:fyp_project2/ai/ai_recipe_gemini.dart';
import 'package:fyp_project2/ai/ai_recipe_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final db = DatabaseService();
  final videoService = VideoService();
  final searchService = SearchService();
  final GeminiService _geminiService = GeminiService();
  String _aiRecipePreview = "";
  bool _isAiLoading = false;

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

  Future<void> _generateAiRecommendation() async {
    try {
      setState(() => _isAiLoading = true);
      final keyword = await db.getMostSearchedKeyword();

      final prefs = await db.getUserPreferences();

      final generated = await _geminiService.generateRecipe(
        keyword,   // ← AI now uses trending search
        prefs,
      );

      if (mounted) {
        setState(() {
          _aiRecipePreview = generated;
          _isAiLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isAiLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'KitchenBuddy',
          style: TextStyle(
            color: Color(0xFFE67E22),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await db.logout();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              readOnly: true,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchDiscoveryScreen())
              ),
              decoration: InputDecoration(
                hintText: 'Search recipe or tutorials',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Explore'),
              Tab(text: 'Video'),
              Tab(text: 'Popular'),
            ],
          ),

          // 3. Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExploreTab(),
                _buildVideoTab(),
                _buildPopularTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. EXPLORE TAB
  Widget _buildExploreTab() {
    return FutureBuilder<List<RecipeModel>>(
      future: searchService.searchRecipes(category: 'All Categories'),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        final recipes = snapshot.data ?? [];

        if (_aiRecipePreview.isEmpty && !_isAiLoading) {
          _generateAiRecommendation();
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // AI SECTION
              _buildAiSection(),

              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "🍳 Fresh Recipes For You",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // NORMAL RECIPES
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(15),
                itemCount: recipes.length,
                itemBuilder: (context, index) =>
                    _buildStandardRecipeCard(recipes[index]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🤖 AI Picks For You",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIRecipePage(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: _isAiLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
                  : Text(
                _aiRecipePreview.isEmpty
                    ? "Tap to generate AI recipe"
                    : _aiRecipePreview.length > 200
                    ? _aiRecipePreview.substring(0, 200) + "..."
                    : _aiRecipePreview,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. VIDEO TAB
  Widget _buildVideoTab() {
    return StreamBuilder<List<VideoModel>>(
      stream: videoService.getVideoStream('All'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final videos = snapshot.data ?? [];

        if (videos.isEmpty) {
          return const Center(child: Text("No tutorials uploaded yet 🍳"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerPage(
                      videoUrl: video.videoUrl,
                      thumbnailUrl: video.thumbnailUrl,
                      title: video.title,
                    ),
                  ),
                );
              },
              child: _buildVideoCard(video),
            );
          },
        );
      },
    );
  }

  // 3. POPULAR TAB

  Widget _buildPopularTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Kitchen Leaderboard",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            "Discover the most popular content on KitchenBuddy",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),

        const SizedBox(height: 20),

        // Most Liked Card
        _buildDiscoveryCard(
          title: "Most Liked Recipes",
          subtitle: "The community's absolute favorites",
          rankType: "likes",
          imageAsset: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=600&auto=format&fit=crop",
          badgeText: "TOP RATED",
        ),

        const SizedBox(height: 20),

        // Top Creators Card
        _buildDiscoveryCard(
          title: "Top Content Creators",
          subtitle: "Chefs with the largest following",
          rankType: "followers",
          imageAsset: "https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=600&auto=format&fit=crop",
          badgeText: "TRENDING",
        ),

        const SizedBox(height: 30),

        const Center(
          child: Text(
            "🍳 More rankings coming soon!",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  // UI HELPER: Large Discovery Card
  Widget _buildDiscoveryCard({
    required String title,
    required String subtitle,
    required String rankType,
    required String imageAsset,
    required String badgeText,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RankingResultsPage(rankType: rankType)),
        );
      },
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: DecorationImage(
            image: NetworkImage(imageAsset),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REFINED WIDGET HELPERS ---
  Widget _buildStandardRecipeCard(RecipeModel recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewRecipePage(recipe: recipe))),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50, height: 50, color: Colors.orange[50],
            child: (recipe.imagePath != null && recipe.imagePath!.isNotEmpty)
                ? Image.network(recipe.imagePath!, fit: BoxFit.cover)
                : const Icon(Icons.restaurant_menu, color: Colors.orange),
          ),
        ),
        title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${recipe.cookingTime}m • ${recipe.skillLevel}"),
        trailing: const Icon(Icons.chevron_right, size: 16),
      ),
    );
  }

  Widget _buildVideoCard(VideoModel video) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.black12,
                  child: video.thumbnailUrl.isNotEmpty
                      ? Image.network(
                    video.thumbnailUrl,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.videocam, color: Colors.grey, size: 50),
                ),
              ),
              if (video.thumbnailUrl.isNotEmpty)
                const Icon(Icons.play_circle_fill, color: Colors.white70, size: 60),

              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(video.skillLevel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
              video.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown)
          ),
          Text(
            video.description,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}