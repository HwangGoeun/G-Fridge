import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ingredient.dart';

class IngredientProvider extends ChangeNotifier {
  List<Ingredient> _ingredients = [];

  static const _ingredientsKey = 'ingredients_list';

  List<Ingredient> get ingredients => _ingredients;

  IngredientProvider() {
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ingredientsString = prefs.getString(_ingredientsKey);
    if (ingredientsString != null) {
      final List<dynamic> ingredientsJson = jsonDecode(ingredientsString);
      _ingredients = ingredientsJson
          .map((json) => Ingredient.fromJson(json as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  Future<void> _saveIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final String ingredientsString =
        jsonEncode(_ingredients.map((i) => i.toJson()).toList());
    await prefs.setString(_ingredientsKey, ingredientsString);
  }

  void addIngredient(Ingredient ingredient) {
    _ingredients.add(ingredient);
    _saveIngredients();
    notifyListeners();
  }

  void increaseQuantity(String id) {
    final index = _ingredients.indexWhere((i) => i.id == id);
    if (index >= 0 && index < _ingredients.length) {
      _ingredients[index].quantity += 0.5;
      _saveIngredients();
      notifyListeners();
    }
  }

  void decreaseQuantity(String id) {
    final index = _ingredients.indexWhere((i) => i.id == id);
    if (index >= 0 && index < _ingredients.length) {
      if (_ingredients[index].quantity > 0.5) {
        _ingredients[index].quantity -= 0.5;
        _saveIngredients();
        notifyListeners();
      } else {
        _ingredients[index].quantity == 0.5;
      }
    }
  }

  void removeIngredient(String id) {
    final index = _ingredients.indexWhere((i) => i.id == id);
    if (index >= 0 && index < _ingredients.length) {
      _ingredients.removeAt(index);
      _saveIngredients();
      notifyListeners();
    }
  }

  void updateIngredient(String id, Ingredient ingredient) {
    final index = _ingredients.indexWhere((i) => i.id == id);
    if (index >= 0 && index < _ingredients.length) {
      _ingredients[index] = ingredient;
      _saveIngredients();
      notifyListeners();
    }
  }
}
