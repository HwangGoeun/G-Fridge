import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class ShoppingCartProvider with ChangeNotifier {
  final List<Ingredient> _cartItems = [];

  List<Ingredient> get cartItems => _cartItems;

  void addItem(Ingredient ingredient) {
    // Check if the item already exists in the cart
    int existingIndex =
        _cartItems.indexWhere((item) => item.id == ingredient.id);

    if (existingIndex != -1) {
      // If it exists, increase the quantity
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        quantity: _cartItems[existingIndex].quantity + ingredient.quantity,
      );
    } else {
      // If it doesn't exist, add the new item
      _cartItems.add(ingredient);
    }
    notifyListeners();
  }

  void removeItem(Ingredient ingredient) {
    _cartItems.removeWhere((item) => item.id == ingredient.id);
    notifyListeners();
  }

  void increaseQuantity(Ingredient ingredient) {
    int index = _cartItems.indexWhere((item) => item.id == ingredient.id);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(
        quantity: _cartItems[index].quantity + 0.5,
      );
      notifyListeners();
    }
  }

  void decreaseQuantity(Ingredient ingredient) {
    int index = _cartItems.indexWhere((item) => item.id == ingredient.id);
    if (index != -1 && _cartItems[index].quantity > 0.5) {
      _cartItems[index] = _cartItems[index].copyWith(
        quantity: _cartItems[index].quantity - 0.5,
      );
      notifyListeners();
    }
  }
}
