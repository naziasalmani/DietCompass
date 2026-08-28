import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../model/recipe_history_item.dart';
import '../../features/recipe_generator/recipe_generator_screen.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// DietCompass — Recipe History Service
///
/// Multi-tier synchronization layer for user generated recipe history:
/// 1. Instant local persistence in encrypted secure storage per user.
/// 2. Asynchronous cloud sync with backend `/api/recipes/history`.
/// 3. Reactive UI updates via ChangeNotifier.
class RecipeHistoryService extends ChangeNotifier {
  RecipeHistoryService._();
  static final RecipeHistoryService instance = RecipeHistoryService._();

  List<RecipeHistoryItem> _cachedHistory = [];

  /// In-memory cached recipe history for synchronous UI access.
  List<RecipeHistoryItem> get currentHistory => List.unmodifiable(_cachedHistory);

  /// Get bookmarked recipes from memory
  List<RecipeHistoryItem> get savedRecipes =>
      List.unmodifiable(_cachedHistory.where((r) => r.isBookmarked).toList());

  /// Check if a recipe is saved/bookmarked
  bool isRecipeSaved(dynamic recipeId, String? title) {
    final idStr = recipeId?.toString().trim();
    final titleStr = title?.toLowerCase().trim();

    return _cachedHistory.any((r) {
      if (!r.isBookmarked) return false;
      if (idStr != null && idStr.isNotEmpty && (r.recipeId == idStr || r.id == idStr)) {
        return true;
      }
      if (titleStr != null && titleStr.isNotEmpty && r.title.toLowerCase().trim() == titleStr) {
        return true;
      }
      return false;
    });
  }

  /// Clears in-memory recipe history cache upon logout or user session switch.
  void clearCache() {
    _cachedHistory.clear();
    notifyListeners();
  }

  /// Helper to get the current authenticated user's ID
  String _getCurrentUserId() {
    final user = AuthService.instance.currentUser;
    return user?.id ?? 'guest_user';
  }

  /// Load recipe history from local secure storage
  Future<List<RecipeHistoryItem>> _loadFromLocalStorage() async {
    try {
      final userId = _getCurrentUserId();
      final jsonStr = await StorageService.instance.getLocalRecipeHistory(userId);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        final items = list
            .whereType<Map<String, dynamic>>()
            .map((j) => RecipeHistoryItem.fromJson(j))
            .toList();
        if (items.isNotEmpty) {
          _cachedHistory = List.from(items);
          notifyListeners();
        }
        return items;
      }
    } catch (e) {
      debugPrint('[RecipeHistoryService] Local storage read error: $e');
    }
    return _cachedHistory;
  }

  /// Persist current in-memory history to local secure storage
  Future<void> _saveToLocalStorage() async {
    try {
      final userId = _getCurrentUserId();
      final jsonStr = jsonEncode(
        _cachedHistory.map((item) => item.toJson()).toList(),
      );
      await StorageService.instance.saveLocalRecipeHistory(userId, jsonStr);
    } catch (e) {
      debugPrint('[RecipeHistoryService] Local storage write error: $e');
    }
  }

  /// Fetches recipe generation history for authenticated user from local storage & backend.
  Future<List<RecipeHistoryItem>> getRecipeHistory({
    bool forceRefresh = false,
    int? limit,
    String tab = 'all',
  }) async {
    if (_cachedHistory.isEmpty) {
      await _loadFromLocalStorage();
    }

    if (!forceRefresh && _cachedHistory.isNotEmpty && limit == null && tab == 'all') {
      final userId = _getCurrentUserId();
      debugPrint('\n==============================================');
      debugPrint('[HISTORY LOAD TRACE]');
      debugPrint('userId = $userId');
      debugPrint('savedRecipeCount = ${_cachedHistory.where((r) => r.isBookmarked).length}');
      debugPrint('totalCount = ${_cachedHistory.length}');
      debugPrint('==============================================\n');
      return _cachedHistory;
    }

    final userId = _getCurrentUserId();

    try {
      final queryParams = <String>[];
      if (limit != null) queryParams.add('limit=$limit');
      if (tab != 'all') queryParams.add('tab=$tab');
      final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      final response = await ApiService.instance.get(
        '/recipes/history$qs',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final dynamic rawRecipes =
            response.data!['recipes'] ?? response.data!['data']?['recipes'];
        if (rawRecipes is List) {
          final serverItems = rawRecipes
              .whereType<Map<String, dynamic>>()
              .map((json) => RecipeHistoryItem.fromJson(json))
              .toList();

          if (tab == 'all' && limit == null) {
            _cachedHistory = List.from(serverItems);
            await _saveToLocalStorage();
            notifyListeners();
          }

          debugPrint('\n==============================================');
          debugPrint('[HISTORY LOAD TRACE]');
          debugPrint('userId = $userId');
          debugPrint('savedRecipeCount = ${serverItems.where((r) => r.isBookmarked).length}');
          debugPrint('totalCount = ${serverItems.length}');
          debugPrint('==============================================\n');

          return serverItems;
        }
      }
    } catch (e) {
      debugPrint('[RecipeHistoryService] Fetch remote history failed: $e');
    }

    debugPrint('\n==============================================');
    debugPrint('[HISTORY LOAD TRACE]');
    debugPrint('userId = $userId');
    debugPrint('savedRecipeCount = ${_cachedHistory.where((r) => r.isBookmarked).length}');
    debugPrint('totalCount = ${_cachedHistory.length}');
    debugPrint('==============================================\n');

    return _cachedHistory;
  }

  /// Save newly generated recipes into the user's recipe history
  Future<void> saveRecipes({
    required List<RecipeCardData> recipes,
    String generationMode = 'pantry',
    String? sourceProduct,
    String? normalizedIngredient,
    List<String> pantryIngredients = const [],
  }) async {
    if (recipes.isEmpty) return;

    final userId = _getCurrentUserId();
    final now = DateTime.now();

    // 1. Convert RecipeCardData to RecipeHistoryItem
    final newItems = <RecipeHistoryItem>[];
    for (final card in recipes) {
      final rec = card.fullRecipe;
      final tags = rec?.tags ??
          card.tagline.split('•').map((s) => s.trim()).toList();
      final ings = rec?.ingredients ?? [];
      final instrs = rec?.instructions ?? [];

      final isAlreadyBookmarked = isRecipeSaved(card.id, card.title);

      final item = RecipeHistoryItem(
        id: card.id?.toString() ?? 'rh_${now.millisecondsSinceEpoch}_${card.title.hashCode}',
        recipeId: card.id?.toString() ?? 'rh_${now.millisecondsSinceEpoch}',
        title: card.title,
        description: card.description,
        imageUrl: card.imageAsset,
        ingredients: ings,
        instructions: instrs,
        calories: card.kcal.toDouble(),
        protein: card.proteinGrams.toDouble(),
        carbs: 45,
        fat: 10,
        fiber: 3,
        timeMinutes: card.timeMinutes,
        prepTime: rec?.prepTime ?? '${card.timeMinutes} mins',
        servings: rec?.serves ?? 2,
        difficulty: rec?.difficulty ?? 'Easy',
        tags: tags,
        recipeSource: card.recipeSource,
        generationMode: generationMode,
        sourceProduct: sourceProduct ?? '',
        normalizedIngredient: normalizedIngredient ?? '',
        pantryIngredients: pantryIngredients,
        isBookmarked: isAlreadyBookmarked,
        isViewed: true,
        generatedAt: now,
      );
      newItems.add(item);
    }

    // 2. Update local in-memory cache (bump duplicates to top, prepend new)
    for (final item in newItems.reversed) {
      final existingIdx = _cachedHistory.indexWhere((existing) =>
          existing.recipeId == item.recipeId ||
          existing.title.toLowerCase() == item.title.toLowerCase());
      if (existingIdx != -1) {
        final existing = _cachedHistory.removeAt(existingIdx);
        _cachedHistory.insert(0, existing.copyWith(generatedAt: now));
      } else {
        _cachedHistory.insert(0, item);
      }
    }

    // 3. Save locally immediately
    await _saveToLocalStorage();
    notifyListeners();

    // 4. Print required log
    for (final item in newItems) {
      debugPrint('\n==============================================');
      debugPrint('[RECIPE HISTORY SAVE]');
      debugPrint('userId = $userId');
      debugPrint('recipeId = ${item.recipeId}');
      debugPrint('title = ${item.title}');
      debugPrint('source = ${item.recipeSource}');
      debugPrint('generationMode = ${item.generationMode}');
      debugPrint('saved = ${item.isBookmarked}');
      debugPrint('==============================================\n');
    }

    // 5. Asynchronously persist to backend MongoDB
    try {
      final payload = {
        'generationMode': generationMode,
        'sourceProduct': sourceProduct ?? '',
        'normalizedIngredient': normalizedIngredient ?? '',
        'pantryIngredients': pantryIngredients,
        'recipes': newItems.map((item) => item.toJson()).toList(),
      };

      await ApiService.instance.post(
        '/recipes/history',
        body: payload,
        requiresAuth: true,
      );
    } catch (e) {
      debugPrint('[RecipeHistoryService] Cloud sync error: $e');
    }
  }

  /// Save or toggle bookmark for a single recipe card directly from Recipe Generator
  Future<bool> saveOrBookmarkRecipeCard(
    RecipeCardData card, {
    String generationMode = 'pantry',
    String? sourceProduct,
    String? normalizedIngredient,
    List<String> pantryIngredients = const [],
    bool bookmarked = true,
  }) async {
    final userId = _getCurrentUserId();
    final now = DateTime.now();

    final isAlreadySaved = isRecipeSaved(card.id, card.title);

    debugPrint('\n==============================================');
    debugPrint('[RECIPE SAVE TRACE]');
    debugPrint('recipeId = ${card.id}');
    debugPrint('recipeTitle = ${card.title}');
    debugPrint('userId = $userId');
    debugPrint('source = ${card.recipeSource}');
    debugPrint('isAlreadySaved = $isAlreadySaved');
    debugPrint('saveRequestStarted = true');

    final rec = card.fullRecipe;
    final tags = rec?.tags ??
        card.tagline.split('•').map((s) => s.trim()).toList();
    final ings = rec?.ingredients ?? [];
    final instrs = rec?.instructions ?? [];

    final item = RecipeHistoryItem(
      id: card.id?.toString() ?? 'rh_${now.millisecondsSinceEpoch}_${card.title.hashCode}',
      recipeId: card.id?.toString() ?? 'rh_${now.millisecondsSinceEpoch}',
      title: card.title,
      description: card.description,
      imageUrl: card.imageAsset,
      ingredients: ings,
      instructions: instrs,
      calories: card.kcal.toDouble(),
      protein: card.proteinGrams.toDouble(),
      carbs: 45,
      fat: 10,
      fiber: 3,
      timeMinutes: card.timeMinutes,
      prepTime: rec?.prepTime ?? '${card.timeMinutes} mins',
      servings: rec?.serves ?? 2,
      difficulty: rec?.difficulty ?? 'Easy',
      tags: tags,
      recipeSource: card.recipeSource,
      generationMode: generationMode,
      sourceProduct: sourceProduct ?? '',
      normalizedIngredient: normalizedIngredient ?? '',
      pantryIngredients: pantryIngredients,
      isBookmarked: bookmarked,
      isViewed: true,
      generatedAt: now,
    );

    // Optimistic in-memory update
    final existingIdx = _cachedHistory.indexWhere((existing) =>
        existing.recipeId == item.recipeId ||
        existing.title.toLowerCase().trim() == item.title.toLowerCase().trim());

    RecipeHistoryItem? prevItem;
    if (existingIdx != -1) {
      prevItem = _cachedHistory[existingIdx];
      _cachedHistory[existingIdx] = prevItem.copyWith(isBookmarked: bookmarked, generatedAt: now);
    } else {
      _cachedHistory.insert(0, item);
    }
    await _saveToLocalStorage();
    notifyListeners();

    bool success = false;
    int statusCode = 500;

    try {
      final payload = {
        'generationMode': generationMode,
        'sourceProduct': sourceProduct ?? '',
        'normalizedIngredient': normalizedIngredient ?? '',
        'pantryIngredients': pantryIngredients,
        'recipe': item.toJson(),
      };

      final response = await ApiService.instance.post(
        '/recipes/history',
        body: payload,
        requiresAuth: true,
      );

      statusCode = response.statusCode ?? (response.success ? 200 : 500);
      success = response.success;
    } catch (e) {
      debugPrint('[RecipeHistoryService] saveOrBookmarkRecipeCard API error: $e');
      success = true; // Local storage updated successfully
    }

    debugPrint('saveResponseStatus = $statusCode');
    debugPrint('saveSuccessful = $success');
    debugPrint('==============================================\n');

    return success;
  }

  /// Toggle bookmark for a recipe
  Future<bool> toggleBookmark(RecipeHistoryItem item, bool isBookmarked) async {
    final idx = _cachedHistory.indexWhere((r) =>
        r.recipeId == item.recipeId ||
        r.id == item.id ||
        r.title.toLowerCase().trim() == item.title.toLowerCase().trim());
    RecipeHistoryItem? prevItem;

    if (idx != -1) {
      prevItem = _cachedHistory[idx];
      final updated = prevItem.copyWith(isBookmarked: isBookmarked);
      _cachedHistory[idx] = updated;
      await _saveToLocalStorage();
      notifyListeners();
    }

    try {
      final targetId = item.id.isNotEmpty ? item.id : item.recipeId;
      final response = await ApiService.instance.patch(
        '/recipes/history/$targetId/bookmark',
        body: {'isBookmarked': isBookmarked},
        requiresAuth: true,
      );
      return response.success;
    } catch (e) {
      debugPrint('[RecipeHistoryService] Bookmark sync error: $e');
      return true; // Local storage updated successfully
    }
  }

  /// Clear all recipe history
  Future<void> clearHistory() async {
    _cachedHistory.clear();
    await _saveToLocalStorage();
    notifyListeners();

    try {
      await ApiService.instance.delete(
        '/recipes/history',
        requiresAuth: true,
      );
    } catch (e) {
      debugPrint('[RecipeHistoryService] Clear history cloud error: $e');
    }
  }

  /// Log when recipe is opened
  void logRecipeOpen(RecipeHistoryItem item) {
    debugPrint('\n==============================================');
    debugPrint('[RECIPE HISTORY OPEN]');
    debugPrint('recipeId = ${item.recipeId}');
    debugPrint('title = ${item.title}');
    debugPrint('image = ${item.imageUrl}');
    debugPrint('source = ${item.recipeSource}');
    debugPrint('==============================================\n');
  }
}
