import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class IngredientProvider extends ChangeNotifier {
  // Initial list with test ingredients (refrigerated, frozen, room temperature)
  final List<Ingredient> _ingredients = [
    // Ingredient(
    //   name: '긴 냉장 재료 이름 테스트',
    //   storageType: StorageType.refrigerated,
    //   quantity: 1.0,
    // ),
    // Ingredient(
    //   name: '긴 냉동 재료 이름 테스트',
    //   storageType: StorageType.frozen,
    //   quantity: 2.5,
    // ),
    // Ingredient(
    //   name: '긴 실온 재료 이름 테스트',
    //   storageType:
    //       StorageType.roomTemperature, // Add room temperature ingredient
    //   quantity: 3.0,
    // ),
  ];

  List<Ingredient> get ingredients => _ingredients;

  void addIngredient(Ingredient ingredient) {
    _ingredients.add(ingredient);
    // 상태 변화를 리스너에게 알립니다.
    notifyListeners();
  }

  void increaseQuantity(int index) {
    if (index >= 0 && index < _ingredients.length) {
      _ingredients[index].quantity += 0.5;
      notifyListeners();
    }
  }

  void decreaseQuantity(int index) {
    if (index >= 0 && index < _ingredients.length) {
      if (_ingredients[index].quantity > 0.5) {
        _ingredients[index].quantity -= 0.5;
        notifyListeners();
      }
    }
  }

  void removeIngredient(int index) {
    if (index >= 0 && index < _ingredients.length) {
      _ingredients.removeAt(index);
      notifyListeners();
    }
  }
}
