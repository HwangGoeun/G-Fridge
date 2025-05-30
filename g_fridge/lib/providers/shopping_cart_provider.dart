import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class ShoppingCartProvider with ChangeNotifier {
  final List<Ingredient> _cartItems = [];

  List<Ingredient> get cartItems => _cartItems;

  void addItem(Ingredient ingredient) {
    // Check if the item already exists in the cart
    int existingIndex =
        _cartItems.indexWhere((item) => item.name == ingredient.name);

    if (existingIndex != -1) {
      // If it exists, increase the quantity
      _cartItems[existingIndex] = Ingredient(
        name: _cartItems[existingIndex].name,
        quantity: _cartItems[existingIndex].quantity +
            ingredient.quantity, // Add new quantity to existing
        storageType: _cartItems[existingIndex]
            .storageType, // Preserve existing storage type, though it might not be strictly needed for cart
      );
    } else {
      // If it doesn't exist, add the new item
      _cartItems.add(ingredient);
    }
    notifyListeners();
  }

  void removeItem(Ingredient ingredient) {
    _cartItems.remove(ingredient);
    notifyListeners();
  }

  void increaseQuantity(Ingredient ingredient) {
    int index = _cartItems.indexOf(ingredient);
    if (index != -1) {
      _cartItems[index] = Ingredient(
        name: ingredient.name,
        quantity: ingredient.quantity + 0.5,
        storageType: ingredient.storageType, // Preserve storage type
      );
      notifyListeners();
    }
  }

  void decreaseQuantity(Ingredient ingredient) {
    int index = _cartItems.indexOf(ingredient);
    if (index != -1 && ingredient.quantity > 0.5) {
      _cartItems[index] = Ingredient(
        name: ingredient.name,
        quantity: ingredient.quantity - 0.5,
        storageType: ingredient.storageType, // Preserve storage type
      );
      notifyListeners();
    }
  }
}
