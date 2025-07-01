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
  String? _myNicknameWithTag;
  bool _isUserReady = false;
  bool get isUserReady => _isUserReady;

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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final nickname = generateDefaultNickname();
        await addOrUpdateMyMemberWithUniqueTag(nickname);
        // 멤버 생성 후 Firestore에 닉네임+태그 저장
        final myMember =
            _fridges.isNotEmpty && _fridges.first.members.isNotEmpty
                ? _fridges.first.members.first
                : null;
        if (myMember != null &&
            myMember['nickname'] != null &&
            myMember['tag'] != null) {
          final nicknameWithTag = "${myMember['nickname']}#${myMember['tag']}";
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'nickname': nicknameWithTag,
          }, SetOptions(merge: true));
        }
      }
      final defaultFridges = [
        Fridge(
          id: 'home',
          name: '우리집 냉장고',
          type: '가정용',
          location: '부엌',
          creatorId: user?.uid ?? '',
          members: _fridges.isNotEmpty ? _fridges.first.members : [],
        ),
        Fridge(
          id: 'office',
          name: '회사 냉장고',
          type: '사무실용',
          location: '사무실',
          creatorId: user?.uid ?? '',
          members: _fridges.isNotEmpty ? _fridges.first.members : [],
        ),
        Fridge(
          id: 'dorm',
          name: '기숙사 냉장고',
          type: '기숙사용',
          location: '기숙사',
          creatorId: user?.uid ?? '',
          members: _fridges.isNotEmpty ? _fridges.first.members : [],
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

  // 앱 실행/로그인 시 Firestore에서 닉네임, 냉장고, 재료 전체 fetch (닉네임만 준비되면 isUserReady true)
  Future<void> initializeFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 닉네임 먼저 fetch (isUserReady는 loadMyNicknameWithTag에서 true로 됨)
      await loadMyNicknameWithTag();
      // 냉장고 fetch
      await fetchFridgesFromFirestore(user.uid);
      // 모든 냉장고 재료 fetch를 병렬로
      await Future.wait(_fridges
          .map((fridge) => fetchIngredientsFromFirestore(user.uid, fridge.id)));
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String savedNickname = '생성자';
      final firestoreNickname = doc.data()?['nickname'];
      if (firestoreNickname != null && firestoreNickname is String) {
        savedNickname = firestoreNickname.split('#').first;
      }
      final fridgeWithCreator = fridge.copyWith(creatorId: user.uid, members: [
        {'nickname': savedNickname, 'tag': '0001', 'uid': user.uid},
      ]);
      _fridges.add(fridgeWithCreator);
      _fridgeIngredients[fridgeWithCreator.id] = [];
      await saveFridgeToFirestore(user.uid, fridgeWithCreator);
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

  // 기본 냉장고 생성
  Future<void> createDefaultFridge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final nickname = generateDefaultNickname();
      await addOrUpdateMyMemberWithUniqueTag(nickname);
      // 멤버 생성 후 Firestore에 닉네임+태그 저장
      final myMember = _fridges.isNotEmpty && _fridges.first.members.isNotEmpty
          ? _fridges.first.members.first
          : null;
      print('[Firestore set] myMember: $myMember');
      if (myMember != null &&
          myMember['nickname'] != null &&
          myMember['tag'] != null) {
        final nicknameWithTag = "${myMember['nickname']}#${myMember['tag']}";
        print('[Firestore set] nicknameWithTag: $nicknameWithTag');
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nickname': nicknameWithTag,
        }, SetOptions(merge: true));
      }
    }
    if (_fridges.isEmpty) {
      final defaultFridge = Fridge(
        id: 'default',
        name: '기본 냉장고',
        type: '가정용',
        location: '부엌',
        creatorId: user?.uid ?? '',
        members: _fridges.isNotEmpty ? _fridges.first.members : [],
      );
      _fridges = [defaultFridge];
      _currentFridgeId = defaultFridge.id;
      _fridgeIngredients[defaultFridge.id] = [];
      await saveFridgeIngredients();
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

  /// Firestore DB에 저장된 닉네임+태그 조합 중복 체크 (nickname_tags 컬렉션 사용)
  Future<bool> isNicknameTagDuplicate(String nickname, String tag) async {
    final docId = '$nickname#$tag';
    final doc = await FirebaseFirestore.instance
        .collection('nickname_tags')
        .doc(docId)
        .get();
    return doc.exists;
  }

  /// 닉네임+태그 등록 (nickname_tags 컬렉션에 등록)
  Future<void> registerNicknameTag(
      String nickname, String tag, String userId) async {
    final docId = '$nickname#$tag';
    await FirebaseFirestore.instance
        .collection('nickname_tags')
        .doc(docId)
        .set({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Firestore에서 내 닉네임+태그를 불러와서 캐싱
  Future<void> loadMyNicknameWithTag() async {
    _isUserReady = false;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _myNicknameWithTag = null;
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
      _myNicknameWithTag = nickname;
    } else {
      _myNicknameWithTag = null;
    }
    _isUserReady = true;
    notifyListeners();
  }

  /// 내 닉네임+태그 반환 (항상 Firestore user doc 기준)
  String? getMyNicknameWithTag() {
    return _myNicknameWithTag;
  }

  /// 닉네임+태그 중복 체크 및 태그 재생성 포함 닉네임 추가/수정 (nickname_tags 컬렉션 활용, Firestore user doc만 업데이트)
  Future<String?> addOrUpdateMyMemberWithUniqueTag(String nickname) async {
    final user = FirebaseAuth.instance.currentUser;
    print('[addOrUpdate] user: $user');
    if (user == null) return '로그인이 필요합니다.';
    // Firestore의 nickname#tag에서 닉네임 추출
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final firestoreNicknameTag = userDoc.data()?['nickname'];
    String firestoreNickname = '';
    String firestoreTag = '';
    if (firestoreNicknameTag != null &&
        firestoreNicknameTag is String &&
        firestoreNicknameTag.contains('#')) {
      firestoreNickname = firestoreNicknameTag.split('#').first.trim();
      firestoreTag = firestoreNicknameTag.split('#').last.trim();
    }
    // 랜덤 태그 생성 함수 (4자리 영문+숫자)
    String generateRandomTag() {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rand = Random.secure();
      return List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    }

    // 닉네임이 같고 userId도 같으면 태그 유지 및 아무것도 하지 않음
    if (firestoreNickname == nickname.trim() && userDoc.exists) {
      print('[addOrUpdate] 닉네임과 userId가 동일하므로 태그 유지: $nickname#$firestoreTag');
      return null;
    } else {
      // 닉네임이 바뀌면 새 태그 생성
      int maxAttempts = 10000;
      String tag = '';
      do {
        tag = generateRandomTag();
        maxAttempts--;
      } while (await isNicknameTagDuplicate(nickname, tag) && maxAttempts > 0);
      if (maxAttempts <= 0) return '태그 생성에 실패했습니다. 다시 시도해 주세요.';
      // Firestore user doc 업데이트
      final nicknameWithTag = "$nickname#$tag";
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'nickname': nicknameWithTag}, SetOptions(merge: true));
      await registerNicknameTag(nickname, tag, user.uid);
      print('[addOrUpdate] Firestore에 닉네임+태그 등록 완료: $nicknameWithTag');
      // 캐시 갱신
      _myNicknameWithTag = nicknameWithTag;
      notifyListeners();
      return null;
    }
  }

  void clear() {
    _fridges = [];
    _fridgeIngredients.clear();
    _currentFridgeId = '';
    _myNicknameWithTag = null;
    _isUserReady = true;
    notifyListeners();
  }

  Future<void> saveFridgeToFirestore(String userId, Fridge fridge) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final nickname = userData?['nickname'];
    if (nickname != null && nickname is String) {
      final updatedMembers = fridge.members.map((m) {
        if (m['nickname'] == nickname) {
          return {
            'nickname': m['nickname']?.toString() ?? '',
            'tag': m['tag']?.toString() ?? '',
            'uid': m['uid']?.toString() ?? '',
          };
        }
        return {
          'nickname': m['nickname']?.toString() ?? '',
          'tag': m['tag']?.toString() ?? '',
          'uid': m['uid']?.toString() ?? '',
        };
      }).toList();
      final updatedFridge = fridge.copyWith(members: updatedMembers);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fridges')
          .doc(fridge.id)
          .set(updatedFridge.toJson());
    }
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
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fridges')
        .get();
    _fridges = snapshot.docs.map((doc) => Fridge.fromJson(doc.data())).toList();
    if (_fridges.isNotEmpty) {
      _currentFridgeId = _fridges.first.id;
    }
    notifyListeners();
  }

  // Firestore에서 멤버 목록 불러오기
  Future<void> fetchMembersFromFirestore(String uid, String fridgeId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fridges')
        .doc(fridgeId)
        .collection('members')
        .get();
    final fridge =
        _fridges.where((f) => f.id == fridgeId).cast<Fridge?>().firstOrNull;
    if (fridge != null) {
      final members = snapshot.docs
          .map((doc) => Fridge.memberFromJson(doc.data()))
          .toList();
      final updated = fridge.copyWith(members: members);
      final idx = _fridges.indexWhere((f) => f.id == fridgeId);
      if (idx != -1) _fridges[idx] = updated;
      notifyListeners();
    }
  }

  // Firestore에 멤버 저장
  Future<void> saveMemberToFirestore(
      String uid, String fridgeId, Map<String, String> member) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fridges')
        .doc(fridgeId)
        .collection('members')
        .doc(member['uid'])
        .set(Fridge.memberToJson(member));
  }

  // Firestore에서 멤버 삭제
  Future<void> removeMemberFromFirestore(
      String uid, String fridgeId, String memberUid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fridges')
        .doc(fridgeId)
        .collection('members')
        .doc(memberUid)
        .delete();
    final fridge =
        _fridges.where((f) => f.id == fridgeId).cast<Fridge?>().firstOrNull;
    if (fridge != null) {
      final members =
          fridge.members.where((m) => m['uid'] != memberUid).toList();
      final updated = fridge.copyWith(members: members);
      final idx = _fridges.indexWhere((f) => f.id == fridgeId);
      if (idx != -1) _fridges[idx] = updated;
      notifyListeners();
    }
  }

  // 닉네임 생성 시 항상 '프렌지' + 랜덤숫자 4자리로 생성
  String generateDefaultNickname() {
    final rand = Random.secure();
    final randomDigits = List.generate(4, (_) => rand.nextInt(10)).join();
    return '프렌지$randomDigits';
  }

  /// 내 멤버가 없으면 닉네임+태그를 강제로 생성/저장 (Firestore 기준으로 판단)
  Future<void> ensureMyMemberExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Firestore에서 내 user 문서 확인
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists &&
        userDoc.data()?['nickname'] != null &&
        (userDoc.data()?['nickname'] as String).isNotEmpty) {
      // 이미 닉네임이 있으면 아무것도 하지 않음
      print(
          '[ensureMyMemberExists] 이미 Firestore에 내 닉네임 있음: \\${userDoc.data()?['nickname']}');
      return;
    }

    // 없으면 랜덤 닉네임 생성 및 저장
    final nickname = generateDefaultNickname();
    await addOrUpdateMyMemberWithUniqueTag(nickname);
    print('[ensureMyMemberExists] Firestore에 내 닉네임 생성: $nickname');
  }
}
