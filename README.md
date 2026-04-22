# KitchenBuddy 
A cross-platform mobile application that uses Hybrid-AI to generate personalized, dietary-compliant recipes based on the ingredients you already have in your pantry.

App Screenshots
(Insert 3 side-by-side images here: 1. The Smart Pantry, 2. The AI Chef generating a recipe, 3. The Admin Dashboard)

Tech Stack

Frontend: Flutter, Dart

Backend & Database: Supabase, PostgreSQL

AI / LLM: Google Gemini 3.1 Flash API

Local Storage: SQLite (for offline caching)

Core Features

Smart Pantry: Uses a Set-Intersection algorithm to match available ingredients to recipes.

AI Chef: Generates strictly formatted vegetarian/halal recipes using prompt-engineered Gemini LLM.

Offline Mode: SQLite caches text data so users can read recipes without Wi-Fi.

Admin Moderation: Optimistic UI dashboard to ban reported users via Supabase Row Level Security.

How to Run Locally
(Add 2 or 3 quick steps on how to do flutter pub get and flutter run)
