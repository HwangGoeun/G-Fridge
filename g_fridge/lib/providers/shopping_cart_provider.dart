import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class ShoppingCartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _fridgeId;
  List<Ingredient> _cartItems = [];

  List<Ingredient> get cartItems => _cartItems;
  List<Ingredient> get refrigeratedItems => _cartItems
      .where((i) => i.storageType == StorageType.refrigerated)
      .toList();
  List<Ingredient> get frozenItems =>
      _cartItems.where((i) => i.storageType == StorageType.frozen).toList();
  List<Ingredient> get roomTemperatureItems => _cartItems
      .where((i) => i.storageType == StorageType.roomTemperature)
      .toList();

  void setFridgeId(String fridgeId) {
    _fridgeId = fridgeId;
    _listenToCartItems();
  }

  void _listenToCartItems() {
    _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('shopping_cart')
        .snapshots()
        .listen((snapshot) {
      _cartItems = snapshot.docs
          .map((doc) => Ingredient.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addItem(Ingredient ingredient) async {
    final querySnapshot = await _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('shopping_cart')
        .where('ingredientName', isEqualTo: ingredient.ingredientName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      await doc.reference.update({
        'quantity': FieldValue.increment(ingredient.quantity),
      });
    } else {
      await _firestore
          .collection('fridges')
          .doc(_fridgeId)
          .collection('shopping_cart')
          .doc(ingredient.id)
          .set(ingredient.toFirestore());
    }
  }

  Future<void> removeItem(String ingredientId) async {
    print('[removeItem] 삭제 시도 id: $ingredientId');
    print('[removeItem] 현재 장바구니 아이템 목록:');
    for (final item in _cartItems) {
      print('  - id: ${item.id}, name: ${item.ingredientName}');
    }
    await _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('shopping_cart')
        .doc(ingredientId)
        .delete();
  }

  Future<void> increaseQuantity(String ingredientId) async {
    await _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('shopping_cart')
        .doc(ingredientId)
        .update({'quantity': FieldValue.increment(0.5)});
  }

  Future<void> decreaseQuantity(String ingredientId) async {
    final docRef = _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('shopping_cart')
        .doc(ingredientId);

    final doc = await docRef.get();
    if (doc.exists && (doc.data()?['quantity'] ?? 0) > 0.5) {
      await docRef.update({'quantity': FieldValue.increment(-0.5)});
    } else if (doc.exists) {
      // If quantity is 0.5 or less, remove the item
      await docRef.delete();
    }
  }

  Future<void> clearCart() async {
    final WriteBatch batch = _firestore.batch();
    final querySnapshot = await _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('shopping_cart')
        .get();

    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
