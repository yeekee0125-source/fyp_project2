import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/search_service.dart';
import '../../services/video_service.dart'; // Added
import '../../models/recipe_model.dart';
import '../../models/video_model.dart';   // Added
import '../auth/login.dart';
import '../recipe/view_recipe.dart';
import '../video/video_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final db = DatabaseService();
  final searchService = SearchService();
  final videoService = VideoService(); // Initialize Video Service

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
        title: const Text('KitchenBuddy',
            style: TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold, fontSize: 22)),
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
          _buildSearchBar(),
          TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Explore'),
              Tab(text: 'Video'),
              Tab(text: 'Popular'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExploreTab(),
                _buildVideoTab(), // Now using live video data
                _buildPopularTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. EXPLORE: Real recipe data
  Widget _buildExploreTab() {
    return FutureBuilder<List<RecipeModel>>(
      future: searchService.searchRecipes(category: 'All Categories'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final recipes = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: recipes.length,
          itemBuilder: (context, index) => _buildStandardRecipeCard(recipes[index]),
        );
      },
    );
  }

  // 2. VIDEO: Updated to use VideoService and VideoModel
  Widget _buildVideoTab() {
    return StreamBuilder<List<VideoModel>>(
      stream: videoService.getVideoStream('All'), // Fetching from the 'videos' table
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading videos: ${snapshot.error}"));
        }

        final videos = snapshot.data ?? [];

        if (videos.isEmpty) {
          return const Center(child: Text("No tutorials uploaded yet 🍳"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerPage(
                      videoUrl: video.videoUrl, // Pass URL from Supabase
                      title: video.title,       // Pass Title from Supabase
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        // Video Thumbnail / Placeholder
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
                              ),
                            ),
                          ),
                        ),
                        // Level Tag (e.g., "Beginner")
                        Positioned(
                          top: 15,
                          left: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              video.skillLevel,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title and Options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            video.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.more_vert, color: Colors.grey),
                      ],
                    ),
                    Text(
                      video.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. POPULAR: Ranking Banners
  Widget _buildPopularTab() {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _buildRankBanner("Ranked by views"),
        _buildRankBanner("Ranked by likes"),
        _buildRankBanner("Ranked by followers"),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildStandardRecipeCard(RecipeModel recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewRecipePage(recipe: recipe))),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50, height: 50,
            color: Colors.orange[50],
            child: (recipe.imagePath != null && recipe.imagePath!.isNotEmpty)
                ? Image.network(recipe.imagePath!, fit: BoxFit.cover)
                : const Icon(Icons.fastfood, color: Colors.orange),
          ),
        ),
        title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${recipe.cookingTime}m • ${recipe.skillLevel}"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildRankBanner(String label) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFFFFE5A5), Color(0xFFF39C12)]),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Search recipe or tutorials',
          prefixIcon: const Icon(Icons.search),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}