import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';
import 'dart:io';
import 'recipe_model.dart';

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
      createdOn DATETIME DEFAULT CURRENT_TIMESTAMP
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
      'role' : role,
    });

    // Cache profile locally (SQLite)
    final db = await database;
    await db.insert('users', {
      'id': user.id,
      'name': name,
      'email': email,
      'phone': phone,
      'role' : role,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    log('User registered successfully');
  }

  // LOGIN USER (ONLINE FIRST)
  Future<bool> loginUser(String email, String password) async {
    try {
      await supabase.auth.signOut();
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
    await supabase.auth.resetPasswordForEmail(email);
  }

  // ---------- PROFILE MANAGEMENT ----------
  // GET CURRENT USER DATA
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [user.id]);

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      // Fallback to Supabase if local is empty
      final data = await supabase.from('users').select().eq('id', user.id).single();
      return data;
    }
  }

  // UPDATE PROFILE (Fulfills Requirement)
  Future<void> updateProfile(String name, String phone) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Update Supabase
    await supabase.from('users').update({
      'name': name,
      'phone': phone,
    }).eq('id', user.id);

    // Update Local
    final db = await database;
    await db.update('users', {
      'name': name,
      'phone': phone,
    }, where: 'id = ?', whereArgs: [user.id]);
  }

  // RECIPE CRUD (SUPABASE + SQLITE)
  // CREATE
  Future<void> addRecipe(RecipeModel recipe) async {
    await supabase.from('recipes').insert(recipe.toMap()); // Supabase
    final db = await database; // SQLite
    await db.insert(
      'recipes',
      recipe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ (ONLINE FIRST, FALLBACK OFFLINE)
  Future<List<RecipeModel>> fetchRecipes() async {
    try {
      final response = await supabase.from('recipes').select();
      return response.map<RecipeModel>((e) {
        return RecipeModel.fromJson(e);
      }).toList();
    } catch (_) {
      final db = await database;
      final data =
      await db.query('recipes', orderBy: 'createdOn DESC');
      return data.map((e) => RecipeModel.fromJson(e)).toList();
    }
  }

  //update
  Future<void> updateRecipe(RecipeModel recipe) async {
    await supabase
        .from('recipes')
        .update(recipe.toMap())
        .eq('id', recipe.id);

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
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //filter by category
  Future<List<RecipeModel>> getRecipesByCategory(String category) async {
    final db = await database;
    final data = await db.query(
      'recipes',
      where: 'category = ?',
      whereArgs: [category],
    );

    return data.map((e) => RecipeModel.fromJson(e)).toList();
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
      final publicUrl = supabase.storage
          .from('recipes')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }


}
