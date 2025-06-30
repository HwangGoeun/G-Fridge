import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/wish.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishListProvider extends ChangeNotifier {
  static const _wishListKey = 'wish_list';
  List<Wish> _wishes = [];

  List<Wish> get wishes => _wishes;

  WishListProvider() {
    _loadWishes();
  }

  Future<void> _loadWishes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? wishString = prefs.getString(_wishListKey);
    if (wishString != null) {
      final List<dynamic> wishJson = jsonDecode(wishString);
      _wishes = wishJson.map((json) => Wish.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveWishes() async {
    final prefs = await SharedPreferences.getInstance();
    final String wishString =
        jsonEncode(_wishes.map((w) => w.toJson()).toList());
    await prefs.setString(_wishListKey, wishString);
  }

  void addWish(Wish wish) {
    _wishes.add(wish);
    _saveWishes();
    notifyListeners();
  }

  void removeWish(int index) {
    _wishes.removeAt(index);
    _saveWishes();
    notifyListeners();
  }
}
