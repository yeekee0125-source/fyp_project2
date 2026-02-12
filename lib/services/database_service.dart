import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';
import 'dart:io';
import '../models/recipe_model.dart';
import 'package:flutter/foundation.dart';

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
      totalViews INTEGER,
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

  // ---------- PROFILE MANAGEMENT ----------
  // GET CURRENT USER DATA
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    // 🌐 WEB → Supabase ONLY
    if (kIsWeb) {
      final data = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      return data;
    }

    // 📱 MOBILE → SQLite first
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

  // RECIPE CRUD (SUPABASE + SQLITE) //jx change to no sqlite
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

  //update
  Future<void> updateRecipe(RecipeModel recipe) async {
    await supabase.from('recipes').update(recipe.toMap()).eq('id', recipe.id);

    final db = await database;
    await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  //delete
  Future<void> deleteRecipe(String id) async {
    await supabase.from('recipes').delete().eq('id', id);

    final db = await database;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
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
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('reported_users').insert({
      'reported_user_id': reportedUserId,
      'reporter_id': user.id,
      'reason': reason,
    });
  }

  Future<List<RecipeModel>> fetchMyRecipes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('recipes')
        .select()
        .eq('user_id', user.id) // CHANGED from 'created_by' to 'user_id'
        .order('createdOn', ascending: false);

    return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
  }


  Future<List<Map<String, dynamic>>> fetchReportedUsers() async {
    if (!await isAdmin()) return [];

    return await supabase
        .from('reported_users')
        .select('id, reason, status, created_at, users!reported_user_id(name, email)')
        .order('created_at', ascending: false);
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await supabase
        .from('reported_users')
        .update({'status': status})
        .eq('id', reportId);
  }

  Future<List<RecipeModel>> fetchPendingRecipes() async {
    final response = await supabase
        .from('recipes')
        .select()
        .eq('status', 'pending');

    return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
  }

  Future<void> approveRecipe(String recipeId) async {
    await supabase.from('recipes').update({'status': 'approved'}).eq('id', recipeId);
  }

  Future<void> rejectRecipe(String recipeId) async {
    await supabase.from('recipes').update({'status': 'rejected'}).eq('id', recipeId);
  }

  //jx
  // 1. Fetch Top Trending (Sort by Views/Likes)
  Future<List<RecipeModel>> fetchTrendingRecipes() async {
    final response = await supabase
        .from('recipes')
        .select()
        .eq('status', 'approved')
        .order('totalViews', ascending: false) // Most viewed first
        .limit(10);

    return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
  }

// 2. Fetch Quick Meals (Filtered by cookingTime)
  Future<List<RecipeModel>> fetchQuickRecipes(int maxMinutes) async {
    final response = await supabase
        .from('recipes')
        .select()
        .eq('status', 'approved')
        .lte('cookingTime', maxMinutes) // lte = Less Than or Equal to
        .order('cookingTime', ascending: true);

    return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
  }

// 3. Increment View Count
// Call this whenever a user clicks to view a recipe detail
  Future<void> incrementViewCount(String recipeId) async {
    // Use a RPC (Remote Procedure Call) if you want perfect accuracy,
    // but for now, this simpler update is fine if you refresh the UI
    try {
      // Fetch latest count first to be safe
      final res = await supabase.from('recipes').select('totalViews').eq('id', recipeId).single();
      int latestViews = res['totalViews'] ?? 0;

      await supabase
          .from('recipes')
          .update({'totalViews': latestViews + 1})
          .eq('id', recipeId);
    } catch (e) {
      log("Error incrementing views: $e");
    }
  }

  // 4. Search with all your new attributes
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

    final response = await request.order('totalViews', ascending: false);
    return response.map<RecipeModel>((e) => RecipeModel.fromJson(e)).toList();
  }

}

