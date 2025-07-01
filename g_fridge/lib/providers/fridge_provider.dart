import 'package:flutter/foundation.dart';
import '../models/fridge.dart';
import '../models/ingredient.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FridgeProvider with ChangeNotifier {
  List<Fridge> _fridges = [];
  final Map<String, List<Ingredient>> _fridgeIngredients = {};
  String _currentFridgeId = '';
  static const _fridgeIngredientsKey = 'fridge_ingredients';
  String? _myNickname;
  bool _isUserReady = false;
  bool get isUserReady => _isUserReady;

  // Getters
  List<Fridge> get fridges {
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
    print('[FridgeProvider] initialize() called');
    final user = FirebaseAuth.instance.currentUser;
    _isUserReady = false;
    notifyListeners();
    if (user != null) {
      print('[FridgeProvider] initialize: user is logged in');
      await initializeFromFirestore();
      if (_fridges.isEmpty) {
        await createDefaultFridge();
      }
    } else {
      print('[FridgeProvider] initialize: user is NOT logged in');
      // 비로그인 상태: 로컬에만 기본 냉장고 생성(최초 1회)
      if (_fridges.isEmpty) {
        final defaultFridge = Fridge(
          id: 'home',
          name: '우리집 냉장고',
          type: '개인용',
          creatorId: '',
        );
        _fridges = [defaultFridge];
        _currentFridgeId = defaultFridge.id;
        _fridgeIngredients[defaultFridge.id] = [];
        await saveFridgeIngredients();
        notifyListeners();
      }
    }
    await loadFridgeIngredients();
    _isUserReady = true;
    print('[FridgeProvider] isUserReady = true');
    notifyListeners();
  }

  // 앱 실행/로그인 시 Firestore에서 닉네임, 냉장고, 재료 전체 fetch (닉네임만 준비되면 isUserReady true)
  Future<void> initializeFromFirestore() async {
    print('[FridgeProvider] initializeFromFirestore() called');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[FridgeProvider] Skipping Firestore fetch: user is null');
      return;
    }
    try {
      await loadMyNickname();
      await fetchFridgesFromFirestore(user.uid);
      print('[FridgeProvider] fetchFridgesFromFirestore finished');
      await Future.wait(_fridges
          .map((fridge) => fetchIngredientsFromFirestore(user.uid, fridge.id)));
      print('[FridgeProvider] fetchIngredientsFromFirestore finished');
      // 마이그레이션: 기존 냉장고 타입을 모두 '개인용'으로 변경
      bool migrated = false;
      for (var i = 0; i < _fridges.length; i++) {
        final f = _fridges[i];
        if (f.type != '개인용') {
          _fridges[i] = f.copyWith(type: '개인용');
          await saveFridgeToFirestore(user.uid, _fridges[i]);
          migrated = true;
        }
      }
      if (migrated) notifyListeners();
      // 반드시 동기화 후 notifyListeners
      notifyListeners();
    } catch (e) {
      print('[FridgeProvider] Firestore fetch error: $e');
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
  Future<void> addFridge(Fridge fridge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Firestore의 doc().id로 고유 id 생성
      final fridgeId = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fridges')
          .doc()
          .id;
      final fridgeWithCreator =
          fridge.copyWith(id: fridgeId, creatorId: user.uid);
      _fridges.add(fridgeWithCreator);
      _fridgeIngredients[fridgeWithCreator.id] = [];
      await saveFridgeToFirestore(user.uid, fridgeWithCreator);
      await initializeFromFirestore(); // 목록 재동기화
      notifyListeners();
    }
  }

  // 냉장고 삭제
  Future<void> removeFridgeFirestore(String fridgeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fridges')
        .doc(fridgeId)
        .delete();
    _fridges.removeWhere((fridge) => fridge.id == fridgeId);
    _fridgeIngredients.remove(fridgeId);
    if (_currentFridgeId == fridgeId && _fridges.isNotEmpty) {
      _currentFridgeId = _fridges.first.id;
    }
    notifyListeners();
  }

  // 기본 냉장고 생성 (Firestore에 냉장고가 없을 때만)
  Future<void> createDefaultFridge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Firestore에 냉장고가 하나도 없을 때만 생성
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('fridges')
            .get();
        if (snapshot.docs.isEmpty) {
          final defaultFridge = Fridge(
            id: 'home',
            name: '우리집 냉장고',
            type: '개인용',
            creatorId: user.uid,
          );
          _fridges = [defaultFridge];
          _currentFridgeId = defaultFridge.id;
          _fridgeIngredients[defaultFridge.id] = [];
          await saveFridgeToFirestore(user.uid, defaultFridge);
          notifyListeners();
        }
      } catch (e) {
        print('[FridgeProvider] createDefaultFridge Firestore error: $e');
      }
    } else {
      // 비로그인 상태: 로컬에만 생성
      if (_fridges.isEmpty) {
        final defaultFridge = Fridge(
          id: 'home',
          name: '우리집 냉장고',
          type: '개인용',
          creatorId: '',
        );
        _fridges = [defaultFridge];
        _currentFridgeId = defaultFridge.id;
        _fridgeIngredients[defaultFridge.id] = [];
        await saveFridgeIngredients();
        notifyListeners();
      }
    }
  }

  // 냉장고가 비어있는지 확인하고 기본 냉장고 생성
  void ensureMinimumFridge() {
    if (_fridges.isEmpty) {
      createDefaultFridge();
    }
  }

  // 현재 냉장고에 재료 추가
  Future<void> addIngredientToCurrentFridge(Ingredient ingredient) async {
    if (_currentFridgeId.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print(
            '[addIngredientToCurrentFridge] user.uid=${user.uid}, fridgeId=$_currentFridgeId, ingredientId=${ingredient.id}');
        await saveIngredientToFirestore(user.uid, _currentFridgeId, ingredient);
        // Firestore에서 재료 목록을 다시 fetch해서 동기화
        await fetchIngredientsFromFirestore(user.uid, _currentFridgeId);
        notifyListeners();
      }
    }
  }

  // 현재 냉장고에서 재료 제거
  Future<void> removeIngredientFromCurrentFridge(String ingredientId) async {
    if (_currentFridgeId.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await removeIngredientFromFirestore(
            user.uid, _currentFridgeId, ingredientId);
        notifyListeners();
      }
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
  Future<void> updateFridgeName(String fridgeId, String newName) async {
    final index = _fridges.indexWhere((f) => f.id == fridgeId);
    if (index != -1) {
      _fridges[index] = _fridges[index].copyWith(name: newName);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await saveFridgeToFirestore(user.uid, _fridges[index]);
      }
      notifyListeners();
    }
  }

  // 냉장고 카테고리(타입) 변경
  Future<void> updateFridgeType(String fridgeId, String newType) async {
    final index = _fridges.indexWhere((f) => f.id == fridgeId);
    if (index != -1) {
      _fridges[index] = _fridges[index].copyWith(type: newType);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await saveFridgeToFirestore(user.uid, _fridges[index]);
      }
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

  Future<void> loadMyNickname() async {
    _isUserReady = false;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _myNickname = null;
      _isUserReady = true;
      notifyListeners();
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final nickname = doc.data()?['nickname'];
    if (nickname != null && nickname is String && nickname.isNotEmpty) {
      _myNickname = nickname;
    } else {
      _myNickname = null;
    }
    _isUserReady = true;
    notifyListeners();
  }

  String? getMyNickname() {
    return _myNickname;
  }

  void clear() {
    _fridges = [];
    _fridgeIngredients.clear();
    _currentFridgeId = '';
    _myNickname = null;
    _isUserReady = true;
    notifyListeners();
  }

  Future<void> saveFridgeToFirestore(String userId, Fridge fridge) async {
    // nickname 여부와 관계없이 무조건 저장
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('fridges')
        .doc(fridge.id)
        .set(fridge.toJson());
  }

  // Firestore에서 재료 목록 불러오기
  Future<void> fetchIngredientsFromFirestore(
      String uid, String fridgeId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fridges')
        .doc(fridgeId)
        .collection('ingredients')
        .get();
    _fridgeIngredients[fridgeId] =
        snapshot.docs.map((doc) => Ingredient.fromJson(doc.data())).toList();
    notifyListeners();
  }

  // Firestore에 재료 저장
  Future<void> saveIngredientToFirestore(
      String uid, String fridgeId, Ingredient ingredient) async {
    print(
        '[saveIngredientToFirestore] path=users/$uid/fridges/$fridgeId/ingredients/${ingredient.id}');
    print('[saveIngredientToFirestore] data=${ingredient.toJson()}');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fridges')
        .doc(fridgeId)
        .collection('ingredients')
        .doc(ingredient.id)
        .set(ingredient.toJson());
  }

  // Firestore에서 재료 삭제
  Future<void> removeIngredientFromFirestore(
      String uid, String fridgeId, String ingredientId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fridges')
        .doc(fridgeId)
        .collection('ingredients')
        .doc(ingredientId)
        .delete();
    _fridgeIngredients[fridgeId]?.removeWhere((i) => i.id == ingredientId);
    notifyListeners();
  }

  // Firestore에서 냉장고 전체 목록 불러오기
  Future<void> fetchFridgesFromFirestore(String uid) async {
    print('[FridgeProvider] fetchFridgesFromFirestore() called');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fridges')
          .get();
      _fridges =
          snapshot.docs.map((doc) => Fridge.fromJson(doc.data())).toList();
      print('[FridgeProvider] _fridges.length = \\${_fridges.length}');
      if (_fridges.isNotEmpty) {
        _currentFridgeId = _fridges.first.id;
      }
      notifyListeners();
    } catch (e) {
      print('[FridgeProvider] fetchFridgesFromFirestore error: $e');
    }
  }

  // 닉네임 생성 시 항상 '프렌지' + 랜덤숫자 4자리로 생성
  String generateDefaultNickname() {
    final rand = Random.secure();
    final randomDigits = List.generate(4, (_) => rand.nextInt(10)).join();
    return '프렌지$randomDigits';
  }
}
