// import 'package:flutter/material.dart';
// import '../../services/database_service.dart';
// import '../admin/admin_dashboard.dart';
// import '../auth/login.dart';
// import '../profile/profile_page.dart';
// import '../recipe/recipe_list.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   final db = DatabaseService();
//   String _role = 'user'; // Default to normal user
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkUserRole();
//   }
//
//   // Fetch the role from DatabaseService
//   void _checkUserRole() async {
//     final userData = await db.getCurrentUserProfile();
//     if (userData != null && mounted) {
//       setState(() {
//         _role = userData['role'] ?? 'user'; // Get role, default to 'user'
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFFF3CC),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFFFF3CC),
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           'KitchenBuddy',
//           style: TextStyle(
//             color: Colors.grey,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.black),
//         actions: [
//           // 2. Add an Admin Icon in the top bar (Optional)
//           // Inside HomePage build method...
//           if (_role == 'admin')
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
//                 label: const Text(
//                   'Admin Dashboard',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.redAccent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 onPressed: () {
//                   // ✅ FIX: Actually navigate to the Admin Dashboard page
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const AdminDashboard()),
//                   );
//                 },
//               ),
//             ),
//           IconButton(
//             icon: const Icon(Icons.person),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const ProfilePage()),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await db.logout();
//               if (mounted) {
//                 Navigator.pushAndRemoveUntil(
//                   context,
//                   MaterialPageRoute(builder: (_) => const LoginPage()),
//                       (route) => false,
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const SizedBox(height: 30),
//
//             /// 👋 Welcome Card
//             Card(
//               color: const Color(0xFFFFE5A5),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     const Icon(Icons.restaurant_menu,
//                         size: 50, color: Colors.orange),
//                     const SizedBox(height: 10),
//                     Text(
//                       _role == 'admin'
//                           ? 'Welcome, Admin!' // Personalized for Admin
//                           : 'Welcome to KitchenBuddy',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     const Text(
//                       'Manage and explore your recipes 🍳',
//                       style: TextStyle(color: Colors.black54),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 40),
//
//             //View Recipes Button
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.list, color: Colors.white),
//                 label: const Text(
//                   'View My Recipes',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const RecipeListPage(),
//                     ),
//                   );
//                 },
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             //ADMIN ONLY BUTTON
//             //This button only appears if the role is 'admin'
//             if (_role == 'admin')
//               SizedBox(
//                 width: double.infinity,
//                 height: 55,
//                 child: ElevatedButton.icon(
//                   icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
//                   label: const Text(
//                     'Admin Dashboard',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.redAccent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const AdminDashboard(),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/search_service.dart';
import '../../models/recipe_model.dart';
import '../auth/login.dart';
import '../recipe/view_recipe.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final db = DatabaseService();
  final searchService = SearchService();

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
      backgroundColor: const Color(0xFFFFFBE6), // Warm yellow background
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
                _buildVideoTab(),
                _buildPopularTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. EXPLORE: Real data using your search logic
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

  // 2. VIDEO: Reverted to your specific Image-First UI
  Widget _buildVideoTab() {
    return FutureBuilder<List<RecipeModel>>(
      future: searchService.searchRecipes(category: 'Video'), //
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final recipes = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewRecipePage(recipe: recipe))),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        // Main Video Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: recipe.imagePath != null && recipe.imagePath!.isNotEmpty
                                ? Image.network(recipe.imagePath!, fit: BoxFit.cover)
                                : Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50)),
                          ),
                        ),
                        // Play Button Overlay (Top Right from image)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 30),
                        ),
                        // Level Tag (Top Left - e.g., "Beginner")
                        Positioned(
                          top: 15,
                          left: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              recipe.skillLevel ?? "Beginner",
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title and More Options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.more_vert, color: Colors.grey),
                      ],
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

  // 3. POPULAR: Banners for ranking categories
  Widget _buildPopularTab() {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _buildRankBanner("Ranked by views", "assets/images/views_bg.jpg"),
        _buildRankBanner("Ranked by likes", "assets/images/likes_bg.jpg"),
        _buildRankBanner("Ranked by followers", "assets/images/followers_bg.jpg"),
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
            child: recipe.imagePath != null ? Image.network(recipe.imagePath!, fit: BoxFit.cover) : const Icon(Icons.fastfood, color: Colors.orange),
          ),
        ),
        title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${recipe.cookingTime}m • ${recipe.skillLevel}"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildRankBanner(String label, String imagePath) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.brown[100], // Background color while image loads
      ),
      child: Stack(
        children: [
          // Banner Title
          Center(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
          filled: true, fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}