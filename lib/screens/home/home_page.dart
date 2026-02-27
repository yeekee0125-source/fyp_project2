import 'package:flutter/material.dart';
import 'package:fyp_project2/screens/home/search_screen.dart';
import 'package:fyp_project2/models/recipe_model.dart';
import 'package:fyp_project2/models/video_model.dart';
import 'package:fyp_project2/services/database_service.dart';
import 'package:fyp_project2/services/search_service.dart';
import 'package:fyp_project2/services/video_service.dart';
import '../auth/login.dart';
import '../recipe/view_recipe.dart';
import '../video/video_player_page.dart';
import 'notification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final db = DatabaseService();
  final videoService = VideoService(); // Added for real data
  final searchService = SearchService(); // Added for real data

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
          // Added Notification Icon
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
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
          // 1. Search Bar (Button Mode)
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

  // EXPLORE
  Widget _buildExploreTab() {
    return FutureBuilder<List<RecipeModel>>(
      future: searchService.searchRecipes(category: 'All Categories'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        final allRecipes = snapshot.data ?? [];

        if (allRecipes.isEmpty) {
          return const Center(child: Text("No recipes found."));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // AI SECTION
              _buildAISection(allRecipes),

              const SizedBox(height: 20),

              //ALL OTHER USERS SECTION
              _buildExploreList(allRecipes),
            ],
          ),
        );
      },
    );
  }


  Widget _buildAISection(List<RecipeModel> recipes) {

    // Simple AI logic: recommend quick beginner recipes
    final aiRecipes = recipes
        .where((r) => r.skillLevel == 'Beginner')
        .take(5)
        .toList();

    if (aiRecipes.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "AI Picks For You",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: aiRecipes.length,
            itemBuilder: (context, index) {
              final recipe = aiRecipes[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: _buildStandardRecipeCard(recipe),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExploreList(List<RecipeModel> recipes) {

    final currentUserId = db.supabase.auth.currentUser?.id;

    final otherUserRecipes =
    recipes.where((r) => r.userId != currentUserId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "Explore Other Users",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(15),
          itemCount: otherUserRecipes.length,
          itemBuilder: (context, index) =>
              _buildStandardRecipeCard(otherUserRecipes[index]),
        ),
      ],
    );
  }

  // 2. VIDEO: Updated to use the Stream from Supabase
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

  // 3. POPULAR: Stays as your previous banners
  Widget _buildPopularTab() {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _buildPopularBanner("Ranked by views"),
        _buildPopularBanner("Ranked by likes"),
        _buildPopularBanner("Ranked by followers"),
      ],
    );
  }

  // --- REFINED WIDGET HELPERS ---

  Widget _buildStandardRecipeCard(RecipeModel recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ViewRecipePage(recipe: recipe))
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50, height: 50,
            color: Colors.orange[50],
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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 60),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text(
                      video.skillLevel,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(
                      video.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown)
                  )
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
    );
  }

  Widget _buildPopularBanner(String text) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFFFFE5A5), Color(0xFFF39C12)]),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}