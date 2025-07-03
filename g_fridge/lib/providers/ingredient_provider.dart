import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import 'dart:async';

class IngredientProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _fridgeId;
  List<Ingredient> _ingredients = [];
  StreamSubscription? _ingredientSubscription;

  List<Ingredient> get ingredients => _ingredients;

  void setFridgeId(String fridgeId) {
    if (_fridgeId == fridgeId && _ingredientSubscription != null) return;
    _fridgeId = fridgeId;
    _ingredientSubscription?.cancel();
    print('[IngredientProvider] Start listening to fridge: $fridgeId');
    _ingredientSubscription = _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('ingredients')
        .orderBy('ingredientName')
        .snapshots()
        .listen((snapshot) {
      print(
          '[IngredientProvider] ingredients updated: ${snapshot.docs.length}');
      _ingredients = snapshot.docs
          .map((doc) => Ingredient.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ingredientSubscription?.cancel();
    super.dispose();
  }

  // 쓰기 관련 메서드(추가/수정/삭제)는 FridgeProvider를 통해서만 처리합니다.
  // IngredientProvider는 읽기/구독만 담당합니다.
}
