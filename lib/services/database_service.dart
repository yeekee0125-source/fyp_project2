import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';
import 'dart:io';
import '../models/recipe_model.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';


class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // ---------- SQLITE ----------
  static Database? _database;

  // ---------- SUPABASE ----------
  final supabase = Supabase.instance.client;

  // ---------- SQLITE INIT ----------
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/kitchenbuddy.db';
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
     CREATE TABLE users(
     id TEXT PRIMARY KEY,
     name TEXT,
     email TEXT,
     phone TEXT,
     role TEXT)
     ''');
    log('Users table created');


    await db.execute('''
  CREATE TABLE recipes(
  id TEXT PRIMARY KEY,
  title TEXT,
  ingredients TEXT,
  steps TEXT,
  category TEXT,
  servings INTEGER,
  imagePath TEXT,
  status TEXT,
  created_by TEXT,
  createdOn DATETIME DEFAULT CURRENT_TIMESTAMP,
  cookingTime INTEGER,
  skillLevel TEXT,
  user_id TEXT
)
''');
    log('Recipes table created');
  }

  // REGISTER USER
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'user',
  }) async {
    final authResponse = await supabase.auth.signUp(
      email: email.trim(),
      password: password.trim(),
    );

    final user = authResponse.user;
    if (user == null) {
      throw Exception('Registration failed');
    }

    // Insert profile into Supabase users table
    await supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    });

    // Cache profile locally (SQLite)
    final db = await database;
    await db.insert('users', {
      'id': user.id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    log('User registered successfully');
  }

  // LOGIN USER (ONLINE FIRST)
  Future<bool> loginUser(String email, String password) async {
    try {
      // Supabase Auth login
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;
      if (user == null) return false;

      // Fetch profile from Supabase
      final profile = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      // Save profile to SQLite
      final db = await database;
      await db.insert('users', {
        'id': user.id,
        'name': profile['name'],
        'email': profile['email'],
        'phone': profile['phone'],
        'role': profile['role'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      log('Login success');
      return true;
    } catch (e) {
      log('Login failed: $e');
      return false;
    }
  }

  // OFFLINE LOGIN (USER LOGGED IN BEFORE)
  Future<bool> offlineLogin() async {
    final db = await database;
    final users = await db.query('users');
    return users.isNotEmpty;
  }

  // LOGOUT
  Future<void> logout() async {
    await supabase.auth.signOut();
    final db = await database;
    await db.delete('users');
  }

  //add role check admin/user
  Future<bool> isAdmin() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [user.id],
    );

    return result.isNotEmpty && result.first['role'] == 'admin';
  }

  // PASSWORD RESET
  Future<void> resetPassword(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutter://reset-password',
    );
  }

  // UPDATE PASSWORD
  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
  }

  // ---------- PROFILE MANAGEMENT ----------
  // GET CURRENT USER DATA
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    // WEB → Supabase ONLY
    if (kIsWeb) {
      final data = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      return data;
    }

    // MOBILE → SQLite first
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [user.id]);

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      final data = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      return data;
    }
  }

  // UPDATE PROFILE (Fulfills Requirement)
  Future<void> updateProfile(String name, String phone) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Update Supabase
    await supabase
        .from('users')
        .update({'name': name, 'phone': phone})
        .eq('id', user.id);

    // Update Local
    final db = await database;
    await db.update(
      'users',
      {'name': name, 'phone': phone},
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // RECIPE CRUD (SUPABASE + SQLITE)
  // jx change to no sqlite
  // CREATE
  Future<void> addRecipe(RecipeModel recipe) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = {
      ...recipe.toMap(),
      'status': 'pending',
      'user_id': user.id, // Links to your public.users table
    };
    await supabase.from('recipes').insert(data);
  }

  // READ (ONLINE FIRST, FALLBACK OFFLINE)
  Future<List<RecipeModel>> fetchRecipes() async {
    try {
      final response = await supabase
          .from('recipes')
          .select()
          .eq('status', 'approved');
      return response.map<RecipeModel>((e) {
        return RecipeModel.fromJson(e);
      }).toList();
    } catch (_) {
      final db = await database;
      final data = await db.query('recipes', orderBy: 'createdOn DESC');
      return data.map((e) => RecipeModel.fromJson(e)).toList();
    }
  }


  // Update Recipe (Both Supabase and SQLite)
  Future<void> updateRecipe(RecipeModel recipe) async {
    try {
      // 1. Update Supabase (This accepts the List natively)
      await supabase.from('recipes').update(recipe.toMap()).eq('id', recipe.id);

      // 2. Prepare data for SQLite
      final db = await database;

      // Create a copy of the map so we don't accidentally break the Supabase format
      final Map<String, dynamic> sqliteData = Map<String, dynamic>.from(recipe.toMap());

      // Convert the List (e.g., ['Dessert', 'Baking']) into a String (e.g., 'Dessert,Baking')
      sqliteData['category'] = recipe.category.join(',');

      // 3. Update SQLite safely
      await db.update(
        'recipes',
        sqliteData,
        where: 'id = ?',
        whereArgs: [recipe.id],
      );
    } catch (e) {
      print('Error updating recipe: $e');
      rethrow;
    }
  }

  // Delete Recipe (Both Supabase and SQLite)
  Future<void> deleteRecipe(String id) async {
    try {
      // 1. Delete from Supabase
      await supabase.from('recipes').delete().eq('id', id);

      // 2. Delete from local SQLite
      final db = await database;
      await db.delete('recipes', where: 'id = ?', whereArgs: [id]);

    } catch (e) {
      print('Error deleting recipe: $e');
      rethrow;
    }
  }

  //filter by category(jx updated)
  Future<List<RecipeModel>> getRecipesByCategory(String category) async {
    try {
      // Try Supabase Array contains filter
      final response = await supabase
          .from('recipes')
          .select()
          .contains('category', [category])
          .eq('status', 'approved');

      return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
    } catch (e) {
      // Fallback to SQLite (using LIKE to find category in comma string)
      final db = await database;
      final data = await db.query(
        'recipes',
        where: 'category LIKE ?',
        whereArgs: ['%$category%'],
      );

      return data.map((e) => RecipeModel.fromJson(e)).toList();
    }
  }

  Future<String?> uploadRecipeImage(File imageFile, String recipeId) async {
    try {
      final supabase = Supabase.instance.client;

      final fileExt = imageFile.path.split('.').last;
      final filePath = '$recipeId.$fileExt';

      // Upload image
      await supabase.storage
          .from('recipes') //
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = supabase.storage.from('recipes').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  //Report user
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
  }) async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    if (currentUser.id == reportedUserId) {
      throw Exception("You cannot report yourself");
    }

    await supabase.from('reports').insert({
      'reported_user_id': reportedUserId,
      'reporter_user_id': currentUser.id,
      'reason': reason,
    });
  }


  Future<List<Map<String, dynamic>>> fetchReportedUsers() async {
    final response = await supabase
        .from('reports')
        .select('''
        id,
        reason,
        status,
        reported_user_id,
        users:reported_user_id (email, name)
      ''')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    final report = await supabase
        .from('reports')
        .select('reported_user_id')
        .eq('id', reportId)
        .single();

    final reportedUserId = report['reported_user_id'];

    // Update report status
    await supabase
        .from('reports')
        .update({'status': status})
        .eq('id', reportId);

    // If banning user
    if (status == 'banned') {
      await supabase
          .from('users')
          .update({'role': 'banned'})
          .eq('id', reportedUserId);
    }
  }

  Future<List<RecipeModel>> fetchMyRecipes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('recipes')
        .select()
        .eq('user_id', user.id)
        .neq('status', 'rejected')
        .order('createdOn', ascending: false);

    return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
  }

  Future<List<RecipeModel>> fetchPendingRecipes() async {
    final response = await supabase
        .from('recipes')
        .select()
        .eq('status', 'pending');

    return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
  }

  //ADMIN SIDE TO MANAGE RECIPE
  //approve recipe
  Future<void> approveRecipe(String recipeId) async {
    await supabase
        .from('recipes')
        .update({'status': 'approved'})
        .eq('id', recipeId);
  }

  Future<RecipeModel?> getRecipeById(String recipeId) async {
    try {
      final data = await supabase
          .from('recipes')
          .select()
          .eq('id', recipeId)
          .single();
      return RecipeModel.fromJson(data);
    } catch (e) {
      log('Error fetching recipe by ID: $e');
      return null;
    }
  }

  //reject the recipe
  Future<void> rejectRecipe(String recipeId) async {
    try {
      // Fetch the recipe to find out WHO created it
      final recipeData = await supabase
          .from('recipes')
          .select('user_id, title')
          .eq('id', recipeId)
          .single();

      final creatorId = recipeData['user_id'];
      final recipeTitle = recipeData['title'];

      // Update the recipe status to rejected
      await supabase.from('recipes').update({'status': 'rejected'}).eq('id', recipeId);

      // Send the rejection notification to the creator
      if (creatorId != null && creatorId.toString().isNotEmpty) {
        await NotificationService().createNotification(
          targetUserId: creatorId.toString(),
          title: 'Recipe Update ❌',
          message: 'Unfortunately, your recipe "$recipeTitle" was not approved.',
          recipeId: recipeId, // Optional: keeps the link so they can still view what got rejected
        );
      }
    } catch (e) {
      log('Error rejecting recipe: $e');
    }
  }


//Fetch Quick Meals (Filtered by cookingTime)
  Future<List<RecipeModel>> fetchQuickRecipes(int maxMinutes) async {
    final response = await supabase
        .from('recipes')
        .select()
        .eq('status', 'approved')
        .lte('cookingTime', maxMinutes) // lte = Less Than or Equal to
        .order('cookingTime', ascending: true);

    return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
  }


  //Search with all your new attributes
  Future<List<RecipeModel>> searchRecipes({
    String? query,
    String? category,
    String? skillLevel,
    int? maxMinutes,
  }) async {
    var request = supabase.from('recipes').select().eq('status', 'approved');

    if (query != null && query.isNotEmpty) {
      request = request.ilike('title', '%$query%');
    }
    if (category != null && category != 'All Categories') {
      request = request.contains('category', [category]);
    }
    if (skillLevel != null) {
      request = request.eq('skillLevel', skillLevel);
    }
    if (maxMinutes != null) {
      request = request.lte('cookingTime', maxMinutes);
    }

    final response = await request.order('createdOn', ascending: false);
    return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
  }

  // ------------------------------------------------
  //  User Preferences for AI
  // ------------------------------------------------

  // 1. Get User Preferences
  Future<List<String>> getUserPreferences() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // We use .maybeSingle() instead of .single() so it doesn't crash
      // if the user row is missing or duplicates exist.
      final data = await supabase
          .from('users')
          .select('preferences')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return [];

      final String? prefString = data['preferences'];

      // Convert "Halal,Spicy" string back into a List ["Halal", "Spicy"]
      if (prefString != null && prefString.isNotEmpty) {
        return prefString.split(',');
      }
    } catch (e) {
      log('Error fetching preferences: $e');
    }
    return [];
  }

  // 2. Save User Preferences
  Future<void> saveUserPreferences(List<String> preferences) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Convert List ["Halal", "Spicy"] -> String "Halal,Spicy"
    // (Supabase stores simple text easier than arrays sometimes)
    final String prefString = preferences.join(',');

    try {
      await supabase
          .from('users')
          .update({'preferences': prefString})
          .eq('id', user.id);
    } catch (e) {
      log('Error saving preferences: $e');
    }
  }

  Future<void> logUserInterest(String keyword) async {
    // If they search "Spicy Chicken", we log "Spicy" and "Chicken"
    // This is a simplified example updating the 'spicy' count by +1
    final user = supabase.auth.currentUser;

    // Logic: Check if row exists. If yes, count++. If no, create row with count=1.
    await supabase.rpc('increment_interest', params: {
      'user_id_param': user!.id,
      'keyword_param': keyword,
    });
  }

  Future<String> getMostSearchedKeyword() async {
    try {
      final result = await supabase
          .from('search_logs')
          .select('keyword, count')
          .order('count', ascending: false)
          .limit(1)
          .maybeSingle();

      return result?['keyword'] ?? 'Chicken';
    } catch (e) {
      return 'Chicken';
    }
  }
}

