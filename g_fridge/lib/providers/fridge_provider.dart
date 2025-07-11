import 'package:flutter/foundation.dart';
import '../models/fridge.dart';
import '../models/ingredient.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';

class FridgeProvider with ChangeNotifier {
  List<Fridge> _fridges = [];
  final Map<String, List<Ingredient>> _fridgeIngredients = {};
  String _currentFridgeId = '';
  static const _fridgeIngredientsKey = 'fridge_ingredients';
  String? _myNickname;
  bool _isUserReady = false;
  bool get isUserReady => _isUserReady;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _fridgeSubscription;

  // Getters
  List<Fridge> get fridges {
    return _fridges;
  }

  String get currentFridgeId => _currentFridgeId;

  Fridge? get currentFridge {
    try {
      return _fridges.firstWhere((fridge) => fridge.id == _currentFridgeId);
    } catch (e) {
      return _fridges.isNotEmpty ? _fridges.first : null;
    }
  }

  List<Ingredient> get currentFridgeIngredients {
    return _fridgeIngredients[_currentFridgeId] ?? [];
  }

  // 냉장고별 재료 가져오기
  List<Ingredient> getIngredientsForFridge(String fridgeId) {
    return _fridgeIngredients[fridgeId] ?? [];
  }

  // 실시간 냉장고 목록 구독
  void listenToFridges(String uid) {
    _fridgeSubscription?.cancel();
    _fridgeSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((userDoc) async {
      final fridgeIds =
          (userDoc.data()?['fridgeIds'] as List?)?.cast<String>() ?? [];
      if (fridgeIds.isEmpty) {
        _fridges = [];
        notifyListeners();
        return;
      }
      final fridgesSnapshot = await FirebaseFirestore.instance
          .collection('fridges')
          .where(FieldPath.documentId, whereIn: fridgeIds)
          .get();
      // fridgeIds 순서대로 정렬
      final fridgeMap = {
        for (var doc in fridgesSnapshot.docs)
          doc.id: Fridge.fromJson(doc.data())
      };
      _fridges = fridgeIds
          .where((id) => fridgeMap.containsKey(id))
          .map((id) => fridgeMap[id]!)
          .toList();
      if (_fridges.isNotEmpty) {
        // 기존에 선택한 냉장고가 리스트에 있으면 그대로 유지, 없을 때만 첫 번째로 변경
        if (!_fridges.any((f) => f.id == _currentFridgeId)) {
          _currentFridgeId = _fridges.first.id;
        }
      } else {
        // 냉장고가 하나도 없으면 currentFridgeId를 빈 문자열로
        _currentFridgeId = '';
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _fridgeSubscription?.cancel();
    super.dispose();
  }

  // 초기화
  Future<void> initialize() async {
    // print('[FridgeProvider] initialize() called');
    final user = FirebaseAuth.instance.currentUser;
    _isUserReady = false;
    notifyListeners();
    try {
      if (user != null) {
        // print('[FridgeProvider] initialize: user is logged in');
        listenToFridges(user.uid); // 실시간 구독 시작
        await initializeFromFirestore();
        if (_fridges.isEmpty) {
          await createDefaultFridge();
        }
      }
      await loadFridgeIngredients();
    } catch (e) {
      // print('[FridgeProvider] initialize error: $e');
    } finally {
      _isUserReady = true;
      // print('[FridgeProvider] isUserReady = true (finally)');
      notifyListeners();
    }
  }

  // 앱 실행/로그인 시 Firestore에서 닉네임, 냉장고, 재료 전체 fetch (닉네임만 준비되면 isUserReady true)
  Future<void> initializeFromFirestore() async {
    // print('[FridgeProvider] initializeFromFirestore() called');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // print('[FridgeProvider] Skipping Firestore fetch: user is null');
      return;
    }
    try {
      await loadMyNickname();
      await fetchFridgesFromFirestore(user.uid);
      // print('[FridgeProvider] fetchFridgesFromFirestore finished');
      await Future.wait(_fridges
          .map((fridge) => fetchIngredientsFromFirestore(user.uid, fridge.id)));
      // print('[FridgeProvider] fetchIngredientsFromFirestore finished');
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
      // print('[FridgeProvider] Firestore fetch error: $e');
    } finally {
      // do nothing here, isUserReady is handled by initialize
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
      final fridgeDocRef =
          FirebaseFirestore.instance.collection('fridges').doc();
      final fridgeId = fridgeDocRef.id;
      final now = DateTime.now().millisecondsSinceEpoch;
      final code = _generateInviteCode();
      final fridgeWithCreator = fridge.copyWith(
        id: fridgeId,
        creatorId: user.uid,
        inviteCodes: [
          {'code': code, 'createdAt': now}
        ],
        sharedWith: [],
      );
      _fridges.add(fridgeWithCreator);
      _fridgeIngredients[fridgeWithCreator.id] = [];
      await fridgeDocRef.set(fridgeWithCreator.toJson());
      // users/{uid} 문서에 fridgeIds 배열에 추가
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fridgeIds': FieldValue.arrayUnion([fridgeId])
      }, SetOptions(merge: true));
      await initializeFromFirestore();
      notifyListeners();
    }
  }

  // 냉장고 삭제
  Future<void> removeFridgeFirestore(String fridgeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // 글로벌 fridges 컬렉션에서 삭제
    await FirebaseFirestore.instance
        .collection('fridges')
        .doc(fridgeId)
        .delete();
    // users/{uid} 문서의 fridgeIds 배열에서 제거
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fridgeIds': FieldValue.arrayRemove([fridgeId])
    });
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
        // Firestore에 내가 소유/참여한 냉장고가 하나도 없을 때만 생성
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final fridgeIds =
            (userDoc.data()?['fridgeIds'] as List?)?.cast<String>() ?? [];
        if (fridgeIds.isEmpty) {
          // 글로벌 fridges 컬렉션에 냉장고 생성
          final fridgeDocRef =
              FirebaseFirestore.instance.collection('fridges').doc();
          final fridgeId = fridgeDocRef.id;
          final now = DateTime.now().millisecondsSinceEpoch;
          final code = _generateInviteCode();
          final defaultFridge = Fridge(
            id: fridgeId,
            name: '우리집 냉장고',
            type: '개인용',
            creatorId: user.uid,
            inviteCodes: [
              {'code': code, 'createdAt': now}
            ],
            sharedWith: [],
          );
          _fridges = [defaultFridge];
          _currentFridgeId = defaultFridge.id;
          _fridgeIngredients[defaultFridge.id] = [];
          await fridgeDocRef.set(defaultFridge.toJson());
          // users/{uid} 문서에 fridgeIds 배열에 추가
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'fridgeIds': FieldValue.arrayUnion([fridgeId])
          }, SetOptions(merge: true));
          notifyListeners();
        }
      } catch (e) {
        // print('[FridgeProvider] createDefaultFridge Firestore error: $e');
      }
    }
  }

  // 냉장고가 비어있는지 확인하고 기본 냉장고 생성
  // Removed ensureMinimumFridge: not needed for non-logged-in users

  // 현재 냉장고에 재료 추가
  Future<void> addIngredientToCurrentFridge(Ingredient ingredient) async {
    if (_currentFridgeId.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // print(
        //     '[addIngredientToCurrentFridge] user.uid=${user.uid}, fridgeId=$_currentFridgeId, ingredientId=${ingredient.id}');
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

  // 현장고의 재료 수량 증가
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

  // 현장고의 재료 수량 감소
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
      await FirebaseFirestore.instance
          .collection('fridges')
          .doc(fridgeId)
          .update({'name': newName});
      notifyListeners();
    }
  }

  // 냉장고 카테고리(타입) 변경
  Future<void> updateFridgeType(String fridgeId, String newType) async {
    final index = _fridges.indexWhere((f) => f.id == fridgeId);
    if (index != -1) {
      _fridges[index] = _fridges[index].copyWith(type: newType);
      await FirebaseFirestore.instance
          .collection('fridges')
          .doc(fridgeId)
          .update({'type': newType});
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
    try {
      _isUserReady = false;
      notifyListeners();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _myNickname = null;
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      // print(
      //     '[FridgeProvider] loadMyNickname: userDoc id=${doc.id}, data=${doc.data()}');
      final nickname = doc.data()?['nickname'];
      if (nickname == null || (nickname is String && nickname.isEmpty)) {
        final defaultNickname = generateDefaultNickname();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'nickname': defaultNickname}, SetOptions(merge: true));
      }
      if (nickname != null && nickname is String && nickname.isNotEmpty) {
        _myNickname = nickname;
      } else {
        _myNickname = null;
      }
    } catch (e, stack) {
      // print('[FridgeProvider] loadMyNickname error: $e');
      // print(stack);
    } finally {
      _isUserReady = true;
      notifyListeners();
    }
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
        .collection('fridges')
        .doc(fridge.id)
        .set(fridge.toJson());
  }

  // Firestore에서 재료 목록 불러오기
  Future<void> fetchIngredientsFromFirestore(
      String uid, String fridgeId) async {
    // print(
    //     '[FridgeProvider] fetchIngredientsFromFirestore() called for fridgeId=$fridgeId');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('fridges')
          .doc(fridgeId)
          .collection('ingredients')
          .get();
      final List<Ingredient> loadedIngredients = [];
      for (final doc in snapshot.docs) {
        // print(
        //     '[FridgeProvider] Try parsing ingredient doc: id=${doc.id}, data=${doc.data()}');
        try {
          final ingredient = Ingredient.fromFirestore(doc.data(), doc.id);
          loadedIngredients.add(ingredient);
          // print(
          //     '[FridgeProvider] Successfully parsed ingredient: id=${doc.id}');
        } catch (e, stack) {
          // print(
          //     '[FridgeProvider] ERROR parsing ingredient: id=${doc.id}, error=$e');
          // print(stack);
        }
      }
      _fridgeIngredients[fridgeId] = loadedIngredients;
      notifyListeners();
    } catch (e) {
      // print('[FridgeProvider] fetchIngredientsFromFirestore error: $e');
    }
  }

  // Firestore에 재료 저장
  Future<void> saveIngredientToFirestore(
      String uid, String fridgeId, Ingredient ingredient) async {
    // print(
    //     '[saveIngredientToFirestore] path=fridges/$fridgeId/ingredients/${ingredient.id}');
    // print('[saveIngredientToFirestore] data=${ingredient.toJson()}');
    await FirebaseFirestore.instance
        .collection('fridges')
        .doc(fridgeId)
        .collection('ingredients')
        .doc(ingredient.id)
        .set(ingredient.toFirestore());
  }

  // Firestore에서 재료 삭제
  Future<void> removeIngredientFromFirestore(
      String uid, String fridgeId, String ingredientId) async {
    await FirebaseFirestore.instance
        .collection('fridges')
        .doc(fridgeId)
        .collection('ingredients')
        .doc(ingredientId)
        .delete();
    _fridgeIngredients[fridgeId]?.removeWhere((i) => i.id == ingredientId);
    notifyListeners();
  }

  // Firestore에서 냉장고 전체 목록 불러오기 (내가 소유/참여한 것만)
  Future<void> fetchFridgesFromFirestore(String uid) async {
    // print('[FridgeProvider] fetchFridgesFromFirestore() called');
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final fridgeIds =
          (userDoc.data()?['fridgeIds'] as List?)?.cast<String>() ?? [];
      if (fridgeIds.isEmpty) {
        _fridges = [];
        notifyListeners();
        return;
      }
      final fridgesSnapshot = await FirebaseFirestore.instance
          .collection('fridges')
          .where(FieldPath.documentId, whereIn: fridgeIds)
          .get();
      final List<Fridge> loadedFridges = [];
      for (final doc in fridgesSnapshot.docs) {
        // print(
        //     '[FridgeProvider] Try parsing fridge doc: id=${doc.id}, data=${doc.data()}');
        try {
          var fridge = Fridge.fromJson(doc.data());
          // sharedWith에 1명 이상 있으면 type을 '공유용'으로 강제
          if (fridge.sharedWith.isNotEmpty) {
            fridge = fridge.copyWith(type: '공유용');
          }
          loadedFridges.add(fridge);
          // print('[FridgeProvider] Successfully parsed fridge: id=${doc.id}');
        } catch (e, stack) {
          // print(
          //     '[FridgeProvider] ERROR parsing fridge: id=${doc.id}, error=$e');
          // print(stack);
        }
      }
      // fridgeIds 배열 순서대로 정렬
      _fridges = fridgeIds
          .map((id) => loadedFridges.firstWhere((f) => f.id == id))
          .toList();
      // print('[FridgeProvider] _fridges.length = \\${_fridges.length}');
      if (_fridges.isNotEmpty) {
        // 기존 선택값이 있으면 유지, 없으면 첫 번째로 변경
        if (!_fridges.any((f) => f.id == _currentFridgeId)) {
          _currentFridgeId = _fridges.first.id;
        }
      }
      notifyListeners();
    } catch (e) {
      // print('[FridgeProvider] fetchFridgesFromFirestore error: $e');
    }
  }

  // 6자리 영문+숫자 초대코드 생성 (재사용)
  String _generateInviteCode() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // 공유하기 버튼에서 호출: 새로운 초대코드 생성 및 Firestore inviteCodes 컬렉션에 저장
  Future<String?> addInviteCodeToFridge(String fridgeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final fridgeIndex = _fridges.indexWhere((f) => f.id == fridgeId);
    if (fridgeIndex == -1) return null;
    final code = _generateInviteCode();
    final now = DateTime.now().millisecondsSinceEpoch;
    // inviteCodes 컬렉션에 저장
    await FirebaseFirestore.instance.collection('inviteCodes').doc(code).set({
      'code': code,
      'fridgeId': fridgeId,
      'createdAt': now,
      'valid': true, // 유효한 코드임을 명시적으로 저장
    });
    return code;
  }

  /// 반환값: {'result': 'success'|'expired'|'used'|'invalid'|'not_found'|'error', 'message': ...}
  Future<Map<String, String>> joinFridgeByCode(String inviteCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'result': 'error', 'message': '로그인이 필요합니다.'};
    try {
      final code = inviteCode.trim();
      final codeDoc = await FirebaseFirestore.instance
          .collection('inviteCodes')
          .doc(code)
          .get();
      if (!codeDoc.exists) {
        return {'result': 'not_found', 'message': '초대코드를 찾을 수 없습니다.'};
      }
      final data = codeDoc.data()!;
      final fridgeId = data['fridgeId'] as String?;
      final createdAt = data['createdAt'] as int?;
      final reason = data['reason']?.toString() ?? '';
      if (fridgeId == null || createdAt == null) {
        await codeDoc.reference.update({'valid': false, 'reason': 'invalid'});
        return {'result': 'invalid', 'message': '유효하지 않은 초대코드입니다.'};
      }
      const expire = Duration(days: 7);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - createdAt > expire.inMilliseconds) {
        await codeDoc.reference.update({'valid': false, 'reason': 'expired'});
        return {'result': 'expired', 'message': '초대코드가 만료되었습니다.'};
      }
      // 1주일 이내면 여러 번 사용 가능. valid, reason은 만료시에만 체크
      // 정상 참여 로직
      final fridgeDoc = await FirebaseFirestore.instance
          .collection('fridges')
          .doc(fridgeId)
          .get();
      if (!fridgeDoc.exists) {
        return {'result': 'invalid', 'message': '냉장고 정보를 찾을 수 없습니다.'};
      }
      final fridgeData = fridgeDoc.data()!;
      final sharedWith = List<String>.from(fridgeData['sharedWith'] ?? []);
      if (!sharedWith.contains(user.uid)) {
        await fridgeDoc.reference.update({
          'sharedWith': FieldValue.arrayUnion([user.uid])
        });
        await fridgeDoc.reference.update({'type': '공유용'});
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fridgeIds': FieldValue.arrayUnion([fridgeId])
        }, SetOptions(merge: true));
      }
      // 초대코드 상태 업데이트는 하지 않음(1주일 동안 계속 사용 가능)
      // 내 냉장고 목록 동기화
      await initializeFromFirestore();
      return {'result': 'success', 'message': '공유 냉장고에 참여했습니다!'};
    } catch (e, stack) {
      print('[joinFridgeByCode] error: $e');
      print(stack);
      return {'result': 'error', 'message': '참여에 실패했습니다: $e'};
    }
  }

  // 닉네임 생성 시 항상 '프렌지' + 랜덤숫자 4자리로 생성
  String generateDefaultNickname() {
    final rand = Random.secure();
    final randomDigits = List.generate(4, (_) => rand.nextInt(10)).join();
    return '프렌지$randomDigits';
  }

  // 냉장고 순서 변경 (드래그&드롭)
  Future<void> moveFridgeOrder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= _fridges.length ||
        newIndex >= _fridges.length) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final fridge = _fridges.removeAt(oldIndex);
    _fridges.insert(newIndex, fridge);
    // fridgeIds 배열 순서 update (사용자별 냉장고 순서)
    final newFridgeIds = _fridges.map((f) => f.id).toList();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fridgeIds': newFridgeIds,
    });
    notifyListeners();
  }

  Future<void> updateIngredientInCurrentFridge(
      Ingredient updatedIngredient) async {
    if (_currentFridgeId.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('fridges')
            .doc(_currentFridgeId)
            .collection('ingredients')
            .doc(updatedIngredient.id)
            .update({
          'ingredientName': updatedIngredient.ingredientName,
          'quantity': updatedIngredient.quantity,
          'storageType':
              updatedIngredient.storageType.toString().split('.').last,
          'expirationDate': updatedIngredient.expirationDate != null
              ? Timestamp.fromDate(updatedIngredient.expirationDate!)
              : null,
        });
        await fetchIngredientsFromFirestore(user.uid, _currentFridgeId);
        notifyListeners();
      }
    }
  }

  // 공유 냉장고에서 나가기
  Future<void> leaveSharedFridge(String fridgeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // users/{uid} 문서의 fridgeIds 배열에서 fridgeId 제거
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fridgeIds': FieldValue.arrayRemove([fridgeId])
    });

    // fridges/{fridgeId} 문서의 sharedWith 배열에서 내 uid 제거
    await FirebaseFirestore.instance
        .collection('fridges')
        .doc(fridgeId)
        .update({
      'sharedWith': FieldValue.arrayRemove([user.uid])
    });

    // provider 내부 상태 동기화
    _fridges.removeWhere((fridge) => fridge.id == fridgeId);
    _fridgeIngredients.remove(fridgeId);
    if (_currentFridgeId == fridgeId && _fridges.isNotEmpty) {
      _currentFridgeId = _fridges.first.id;
    } else if (_fridges.isEmpty) {
      _currentFridgeId = '';
    }
    notifyListeners();
  }
}
