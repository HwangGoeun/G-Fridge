import 'package:flutter/foundation.dart';
import '../models/fridge.dart';
import '../models/ingredient.dart';
import '../utils/device_id_util.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FridgeProvider with ChangeNotifier {
  List<Fridge> _fridges = [];
  final Map<String, List<Ingredient>> _fridgeIngredients = {};
  String _currentFridgeId = '';
  static const _fridgeIngredientsKey = 'fridge_ingredients';

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
  Future<void> initialize() async {
    if (_fridges.isEmpty) {
      final deviceId = await DeviceIdUtil.getDeviceId();
      final defaultFridges = [
        Fridge(
          id: 'home',
          name: '우리집 냉장고',
          type: '가정용',
          location: '부엌',
          creatorId: deviceId,
          members: [deviceId],
        ),
        Fridge(
          id: 'office',
          name: '회사 냉장고',
          type: '사무실용',
          location: '사무실',
          creatorId: deviceId,
          members: [deviceId],
        ),
        Fridge(
          id: 'dorm',
          name: '기숙사 냉장고',
          type: '기숙사용',
          location: '기숙사',
          creatorId: deviceId,
          members: [deviceId],
        ),
      ];
      _fridges = defaultFridges;
      _currentFridgeId = defaultFridges.first.id;
      for (var fridge in defaultFridges) {
        _fridgeIngredients[fridge.id] = [];
      }
      await saveFridgeIngredients();
      notifyListeners();
    } else {
      ensureMinimumFridge();
    }
    await loadFridgeIngredients();
  }

  // 현재 냉장고 변경
  void setCurrentFridge(String fridgeId) {
    if (_fridges.any((fridge) => fridge.id == fridgeId)) {
      _currentFridgeId = fridgeId;
      notifyListeners();
    }
  }

  // 냉장고 추가
  Future<void> addFridge(Fridge fridge) async {
    final deviceId = await DeviceIdUtil.getDeviceId();
    final fridgeWithCreator =
        fridge.copyWith(creatorId: deviceId, members: [deviceId]);
    _fridges.add(fridgeWithCreator);
    _fridgeIngredients[fridgeWithCreator.id] = [];
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
  Future<void> createDefaultFridge() async {
    final deviceId = await DeviceIdUtil.getDeviceId();
    if (_fridges.isEmpty) {
      final defaultFridge = Fridge(
        id: 'default',
        name: '기본 냉장고',
        type: '가정용',
        location: '부엌',
        creatorId: deviceId,
        members: [deviceId],
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
      saveFridgeIngredients();
      notifyListeners();
    }
  }

  // 현재 냉장고에서 재료 제거
  void removeIngredientFromCurrentFridge(String ingredientId) {
    if (_currentFridgeId.isNotEmpty) {
      _fridgeIngredients[_currentFridgeId]?.removeWhere(
        (ingredient) => ingredient.id == ingredientId,
      );
      saveFridgeIngredients();
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
          saveFridgeIngredients();
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
        if (index != -1 && ingredients[index].quantity > 0.5) {
          ingredients[index] = ingredients[index].copyWith(
            quantity: ingredients[index].quantity - 0.5,
          );
          saveFridgeIngredients();
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
    saveFridgeIngredients();
    notifyListeners();
  }

  // 특정 냉장고에서 재료 제거
  void removeIngredientFromFridge(String fridgeId, String ingredientId) {
    _fridgeIngredients[fridgeId]?.removeWhere(
      (ingredient) => ingredient.id == ingredientId,
    );
    saveFridgeIngredients();
    notifyListeners();
  }

  // 냉장고 이름 변경
  void updateFridgeName(String fridgeId, String newName) {
    final index = _fridges.indexWhere((f) => f.id == fridgeId);
    if (index != -1) {
      _fridges[index] = _fridges[index].copyWith(name: newName);
      notifyListeners();
    }
  }

  // 냉장고 카테고리(타입) 변경
  void updateFridgeType(String fridgeId, String newType) {
    final index = _fridges.indexWhere((f) => f.id == fridgeId);
    if (index != -1) {
      _fridges[index] = _fridges[index].copyWith(type: newType);
      notifyListeners();
    }
  }

  Future<void> saveFridgeIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _fridgeIngredients.map((fridgeId, ingredients) =>
        MapEntry(fridgeId, ingredients.map((i) => i.toJson()).toList()));
    await prefs.setString(_fridgeIngredientsKey, jsonEncode(data));
  }

  Future<void> loadFridgeIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString(_fridgeIngredientsKey);
    if (dataString != null) {
      final Map<String, dynamic> data = jsonDecode(dataString);
      _fridgeIngredients.clear();
      data.forEach((fridgeId, ingredientList) {
        _fridgeIngredients[fridgeId] = (ingredientList as List)
            .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
            .toList();
      });
      notifyListeners();
    }
  }
}
