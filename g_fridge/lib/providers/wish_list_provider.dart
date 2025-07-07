import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/wish.dart';

class WishListProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _fridgeId;
  List<Wish> _wishes = [];

  List<Wish> get wishes => _wishes;

  void setFridgeId(String fridgeId) {
    _fridgeId = fridgeId;
    _listenToWishes();
  }

  void _listenToWishes() {
    _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('wishes')
        .snapshots()
        .listen((snapshot) {
      _wishes = snapshot.docs
          .map((doc) => Wish.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addWish(Wish wish) async {
    if (_fridgeId.isEmpty) {
      throw Exception('fridgeId가 설정되지 않았습니다. setFridgeId를 먼저 호출하세요.');
    }
    await _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('wishes')
        .add(wish.toFirestore());
  }

  Future<void> removeWish(String wishId) async {
    if (_fridgeId.isEmpty) {
      throw Exception('fridgeId가 설정되지 않았습니다. setFridgeId를 먼저 호출하세요.');
    }
    await _firestore
        .collection('fridges')
        .doc(_fridgeId)
        .collection('wishes')
        .doc(wishId)
        .delete();
  }
}
