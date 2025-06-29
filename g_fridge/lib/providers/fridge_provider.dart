import 'package:flutter/foundation.dart';
import '../models/fridge.dart';
import '../models/ingredient.dart';

class FridgeProvider with ChangeNotifier {
  List<Fridge> _fridges = [];
  final Map<String, List<Ingredient>> _fridgeIngredients = {};
  String _currentFridgeId = '';

  // Getters
  List<Fridge> get fridges {
    // 냉장고가 없으면 기본 냉장고 생성
    if (_fridges.isEmpty) {
      createDefaultFridge();
    }
    return _fridges;
  }

  String get currentFridgeId => _currentFridgeId;

  Fridge? get currentFridge {
    // 냉장고가 없으면 기본 냉장고 생성
    if (_fridges.isEmpty) {
      createDefaultFridge();
    }

    try {
      return _fridges.firstWhere((fridge) => fridge.id == _currentFridgeId);
    } catch (e) {
      return _fridges.isNotEmpty ? _fridges.first : null;
    }
  }

  List<Ingredient> get currentFridgeIngredients {
    // 냉장고가 없으면 기본 냉장고 생성
    if (_fridges.isEmpty) {
      createDefaultFridge();
    }

    return _fridgeIngredients[_currentFridgeId] ?? [];
  }

  // 냉장고별 재료 가져오기
  List<Ingredient> getIngredientsForFridge(String fridgeId) {
    return _fridgeIngredients[fridgeId] ?? [];
  }

  // 초기화
  void initialize() {
    if (_fridges.isEmpty) {
      // 기본 냉장고들 추가
      final defaultFridges = [
        Fridge(
          id: 'home',
          name: '우리집 냉장고',
          type: '가정용',
          location: '부엌',
        ),
        Fridge(
          id: 'office',
          name: '회사 냉장고',
          type: '사무실용',
          location: '사무실',
        ),
        Fridge(
          id: 'dorm',
          name: '기숙사 냉장고',
          type: '기숙사용',
          location: '기숙사',
        ),
      ];

      _fridges = defaultFridges;
      _currentFridgeId = defaultFridges.first.id;

      // 각 냉장고별로 빈 재료 리스트 초기화
      for (var fridge in defaultFridges) {
        _fridgeIngredients[fridge.id] = [];
      }

      notifyListeners();
    } else {
      // 이미 냉장고가 있으면 최소 하나는 있는지 확인
      ensureMinimumFridge();
    }
  }

  // 현재 냉장고 변경
  void setCurrentFridge(String fridgeId) {
    if (_fridges.any((fridge) => fridge.id == fridgeId)) {
      _currentFridgeId = fridgeId;
      notifyListeners();
    }
  }

  // 냉장고 추가
  void addFridge(Fridge fridge) {
    _fridges.add(fridge);
    _fridgeIngredients[fridge.id] = [];
    notifyListeners();
  }

  // 냉장고 삭제
  void removeFridge(String fridgeId) {
    // 최소 하나의 냉장고는 항상 유지
    if (_fridges.length <= 1) {
      return; // 냉장고가 하나뿐이면 삭제 불가
    }

    _fridges.removeWhere((fridge) => fridge.id == fridgeId);
    _fridgeIngredients.remove(fridgeId);

    // 현재 냉장고가 삭제된 경우 첫 번째 냉장고로 변경
    if (_currentFridgeId == fridgeId && _fridges.isNotEmpty) {
      _currentFridgeId = _fridges.first.id;
    }

    notifyListeners();
  }

  // 기본 냉장고 생성
  void createDefaultFridge() {
    if (_fridges.isEmpty) {
      final defaultFridge = Fridge(
        id: 'default',
        name: '기본 냉장고',
        type: '가정용',
        location: '부엌',
      );
      _fridges.add(defaultFridge);
      _fridgeIngredients[defaultFridge.id] = [];
      _currentFridgeId = defaultFridge.id;
      notifyListeners();
    }
  }

  // 냉장고가 비어있는지 확인하고 기본 냉장고 생성
  void ensureMinimumFridge() {
    if (_fridges.isEmpty) {
      createDefaultFridge();
    }
  }

  // 현재 냉장고에 재료 추가
  void addIngredientToCurrentFridge(Ingredient ingredient) {
    if (_currentFridgeId.isNotEmpty) {
      if (!_fridgeIngredients.containsKey(_currentFridgeId)) {
        _fridgeIngredients[_currentFridgeId] = [];
      }
      _fridgeIngredients[_currentFridgeId]!.add(ingredient);
      notifyListeners();
    }
  }

  // 현재 냉장고에서 재료 제거
  void removeIngredientFromCurrentFridge(String ingredientId) {
    if (_currentFridgeId.isNotEmpty) {
      _fridgeIngredients[_currentFridgeId]?.removeWhere(
        (ingredient) => ingredient.id == ingredientId,
      );
      notifyListeners();
    }
  }

  // 현재 냉장고의 재료 수량 증가
  void increaseQuantityInCurrentFridge(String ingredientId) {
    if (_currentFridgeId.isNotEmpty) {
      final ingredients = _fridgeIngredients[_currentFridgeId];
      if (ingredients != null) {
        final index = ingredients.indexWhere((i) => i.id == ingredientId);
        if (index != -1) {
          ingredients[index] = ingredients[index].copyWith(
            quantity: ingredients[index].quantity + 1,
          );
          notifyListeners();
        }
      }
    }
  }

  // 현재 냉장고의 재료 수량 감소
  void decreaseQuantityInCurrentFridge(String ingredientId) {
    if (_currentFridgeId.isNotEmpty) {
      final ingredients = _fridgeIngredients[_currentFridgeId];
      if (ingredients != null) {
        final index = ingredients.indexWhere((i) => i.id == ingredientId);
        if (index != -1 && ingredients[index].quantity > 1) {
          ingredients[index] = ingredients[index].copyWith(
            quantity: ingredients[index].quantity - 1,
          );
          notifyListeners();
        }
      }
    }
  }

  // 특정 냉장고에 재료 추가
  void addIngredientToFridge(String fridgeId, Ingredient ingredient) {
    if (!_fridgeIngredients.containsKey(fridgeId)) {
      _fridgeIngredients[fridgeId] = [];
    }
    _fridgeIngredients[fridgeId]!.add(ingredient);
    notifyListeners();
  }

  // 특정 냉장고에서 재료 제거
  void removeIngredientFromFridge(String fridgeId, String ingredientId) {
    _fridgeIngredients[fridgeId]?.removeWhere(
      (ingredient) => ingredient.id == ingredientId,
    );
    notifyListeners();
  }
}
