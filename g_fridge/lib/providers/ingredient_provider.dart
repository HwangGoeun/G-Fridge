import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class IngredientProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _fridgeId;
  List<Ingredient> _ingredients = [];

  List<Ingredient> get ingredients => _ingredients;

  void setFridgeId(String fridgeId) {
    _fridgeId = fridgeId;
    _listenToIngredients();
  }

  void _listenToIngredients() {
    _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('ingredients')
        .orderBy('ingredientName')
        .snapshots()
        .listen((snapshot) {
      _ingredients = snapshot.docs
          .map((doc) => Ingredient.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addIngredient(Ingredient ingredient) async {
    await _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('ingredients')
        .add(ingredient.toFirestore());
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    await _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('ingredients')
        .doc(ingredient.id)
        .update(ingredient.toFirestore());
  }

  Future<void> removeIngredient(String ingredientId) async {
    await _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('ingredients')
        .doc(ingredientId)
        .delete();
  }

  Future<void> increaseQuantity(String ingredientId) async {
    final docRef = _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('ingredients')
        .doc(ingredientId);
    await docRef.update({'quantity': FieldValue.increment(0.5)});
  }

  Future<void> decreaseQuantity(String ingredientId) async {
    final docRef = _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('ingredients')
        .doc(ingredientId);

    final doc = await docRef.get();
    if (doc.exists && (doc.data()?['quantity'] ?? 0) > 0.5) {
      await docRef.update({'quantity': FieldValue.increment(-0.5)});
    }
  }
}
