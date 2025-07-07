import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fridge_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../models/fridge.dart';
import 'fridge_screen.dart';

class FridgeInfoScreen extends StatefulWidget {
  const FridgeInfoScreen({super.key});

  @override
  State<FridgeInfoScreen> createState() => _FridgeInfoScreenState();
}

class _FridgeInfoScreenState extends State<FridgeInfoScreen> {
  bool _editingName = false;
  late TextEditingController _nameController;
  List<Map<String, dynamic>> _memberInfos = [];
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    final fridge =
        Provider.of<FridgeProvider>(context, listen: false).currentFridge;
    _nameController = TextEditingController(text: fridge?.name ?? '');
    _fetchMemberInfos();
  }

  Future<void> _fetchMemberInfos() async {
    setState(() => _isLoadingMembers = true);
    final fridge =
        Provider.of<FridgeProvider>(context, listen: false).currentFridge;
    if (fridge == null) {
      setState(() {
        _memberInfos = [];
        _isLoadingMembers = false;
      });
      return;
    }
    final memberUids = {fridge.creatorId, ...fridge.sharedWith}.toList();
    List<Map<String, dynamic>> infos = [];
    for (var i = 0; i < memberUids.length; i += 10) {
      final batch = memberUids.skip(i).take(10).toList();
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in query.docs) {
        final data = doc.data();
        String display =
            data['nickname'] ?? data['email'] ?? '${doc.id.substring(0, 8)}...';
        infos.add({
          'uid': doc.id,
          'display': display,
          'email': data['email'] ?? '',
          'nickname': data['nickname'] ?? '',
        });
      }
    }
    setState(() {
      _memberInfos = infos;
      _isLoadingMembers = false;
    });
  }

  Future<void> _kickMember(String uid) async {
    final fridgeProvider = Provider.of<FridgeProvider>(context, listen: false);
    final fridge = fridgeProvider.currentFridge;
    if (fridge == null) return;
    if (uid == fridge.creatorId) return; // 본인은 강퇴 불가
    // Firestore에서 sharedWith에서 해당 uid 제거
    await FirebaseFirestore.instance
        .collection('fridges')
        .doc(fridge.id)
        .update({
      'sharedWith': FieldValue.arrayRemove([uid])
    });
    // UI 갱신
    await _fetchMemberInfos();
    await fridgeProvider.initializeFromFirestore();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여자를 강퇴했습니다.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName(String fridgeId) {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      Provider.of<FridgeProvider>(context, listen: false)
          .updateFridgeName(fridgeId, newName);
      setState(() {
        _editingName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fridgeProvider = Provider.of<FridgeProvider>(context);
    if (!fridgeProvider.isUserReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final fridge = fridgeProvider.currentFridge;
    final creatorId = fridge?.creatorId ?? '알 수 없음';
    final fridgeName = fridge?.name ?? '이름 없음';
    final fridgeId = fridge?.id ?? '';
    final user = FirebaseAuth.instance.currentUser;
    String displayType = fridge?.type ?? '';
    if (fridge != null &&
        fridge.type == '개인용' &&
        fridge.sharedWith.isNotEmpty) {
      displayType = '공유용';
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 냉장고 이름 카드
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.kitchen, color: Colors.blue[600]),
                        const SizedBox(width: 10),
                        const Text(
                          '냉장고 이름',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const Spacer(),
                        if (!_editingName &&
                            user != null &&
                            user.uid == creatorId)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: '이름 수정',
                            onPressed: () {
                              setState(() {
                                _editingName = true;
                                _nameController.text = fridgeName;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_editingName && user != null && user.uid == creatorId)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              onSubmitted: (_) => _saveName(fridgeId),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => _saveName(fridgeId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                textStyle: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(0, 48),
                              ),
                              child: const Text('확인'),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        fridgeName,
                        style: const TextStyle(
                            fontSize: 20, color: Colors.black87),
                      ),
                  ],
                ),
              ),
            ),
            // 냉장고 카테고리(타입) 카드
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.blue[600]),
                    const SizedBox(width: 10),
                    const Text(
                      '카테고리',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    Text(displayType,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87)),
                  ],
                ),
              ),
            ),
            // 냉장고 공유 카드 (로그인 시에만 노출)
            if (FirebaseAuth.instance.currentUser != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.share, color: Colors.blue[600]),
                          const SizedBox(width: 10),
                          const Text(
                            '냉장고 공유하기',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '다른 사람과 냉장고를 함께 관리할 수 있습니다.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final fridgeProvider = Provider.of<FridgeProvider>(
                                context,
                                listen: false);
                            final fridge = fridgeProvider.currentFridge;
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null || fridge == null) {
                              // 로그인 유도 및 마이그레이션
                              // 1. 로그인 유도
                              final loginResult = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('로그인 필요'),
                                  content: const Text(
                                      '공유 기능을 사용하려면 로그인이 필요합니다. 로그인하시겠습니까?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('취소'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('로그인'),
                                    ),
                                  ],
                                ),
                              );
                              if (loginResult != true) return;
                              // 실제 로그인 로직 (구글 등)
                              // 로그인 후 Firestore에 새 냉장고 생성 및 데이터 마이그레이션
                              // (여기서는 login_screen.dart의 GoogleAuthHelper 사용 가정)
                              await GoogleAuthHelper.signInWithGoogle(context);
                              final userAfter =
                                  FirebaseAuth.instance.currentUser;
                              if (userAfter == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('로그인에 실패했습니다.')),
                                );
                                return;
                              }
                              // Firestore에 새 냉장고 생성
                              final newFridge = Fridge(
                                name: fridge?.name ?? '내 냉장고',
                                type: '공유용',
                                creatorId: userAfter.uid,
                              );
                              await fridgeProvider.addFridge(newFridge);
                              // 기존 로컬 냉장고 재료 복사
                              final localIngredients =
                                  fridgeProvider.currentFridgeIngredients;
                              for (final ingredient in localIngredients) {
                                await fridgeProvider
                                    .addIngredientToCurrentFridge(ingredient);
                              }
                              // 안내 및 공유 코드 표시
                              final newFridgeId =
                                  fridgeProvider.currentFridge?.id;
                              if (newFridgeId != null) {
                                final shareText =
                                    'G-Fridge에서 [${newFridge.name}] 냉장고를 함께 관리해요!\n\n초대 ID: $newFridgeId';
                                Share.share(shareText);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('공유 냉장고로 전환되었습니다!')),
                              );
                            } else {
                              // 새로운 초대코드 생성 및 Firestore에 추가
                              final code = await fridgeProvider
                                  .addInviteCodeToFridge(fridge.id);
                              if (code == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('초대코드를 생성할 수 없습니다.')),
                                );
                                return;
                              }
                              final expireDate =
                                  DateTime.now().add(const Duration(days: 7));
                              final expireStr =
                                  '${expireDate.year}.${expireDate.month.toString().padLeft(2, '0')}.${expireDate.day.toString().padLeft(2, '0')}까지 유효';
                              final shareText =
                                  'G-Fridge에서 [${fridge.name}] 냉장고를 함께 관리해요!\n\n초대코드: $code\n($expireStr)';
                              Share.share(shareText);
                            }
                          },
                          icon: const Icon(Icons.group_add),
                          label: const Text('냉장고 공유하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            // 냉장고 참여자 리스트
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group, color: Colors.blue[600]),
                        const SizedBox(width: 10),
                        const Text('참여자',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _isLoadingMembers
                        ? const Center(child: CircularProgressIndicator())
                        : _memberInfos.isEmpty
                            ? const Text('참여자가 없습니다.',
                                style: TextStyle(color: Colors.grey))
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _memberInfos.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 16),
                                itemBuilder: (context, idx) {
                                  final info = _memberInfos[idx];
                                  final isCreator =
                                      user != null && user.uid == creatorId;
                                  final isSelf =
                                      user != null && user.uid == info['uid'];
                                  return Row(
                                    children: [
                                      const Icon(Icons.person,
                                          size: 20, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          info['display'] ?? '',
                                          style: const TextStyle(fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // 강퇴 버튼: creator만, 본인은 불가
                                      if (isCreator && !isSelf)
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.red,
                                              size: 20),
                                          tooltip: '강퇴',
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('참여자 강퇴'),
                                                content: Text(
                                                    '정말로 ${info['display']}님을 강퇴하시겠습니까?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(false),
                                                    child: const Text('취소'),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                Colors.red),
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                    child: const Text('강퇴'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await _kickMember(info['uid']);
                                            }
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
            // 냉장고 삭제 버튼 (페이지 하단)
            const SizedBox(height: 24),
            if (user != null && user.uid == creatorId)
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('냉장고 삭제하기',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                onPressed: () async {
                  final fridgeProvider =
                      Provider.of<FridgeProvider>(context, listen: false);
                  final fridge = fridgeProvider.currentFridge;
                  if (fridge == null) return;
                  // 냉장고가 1개만 남아있으면 삭제 방지
                  if (fridgeProvider.fridges.length <= 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('냉장고는 최소 한 개가 있어야 합니다')),
                    );
                    return;
                  }
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('냉장고 삭제',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '정말로 "${fridge.name}" 냉장고를\n삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('취소'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                  if (confirm == true) {
                    await fridgeProvider.removeFridgeFirestore(fridge.id);
                    if (mounted) {
                      if (fridgeProvider.fridges.isNotEmpty) {
                        // order가 가장 작은 냉장고로 이동 → 리스트 첫 번째 냉장고로 이동
                        final nextFridge = fridgeProvider.fridges.first;
                        fridgeProvider.setCurrentFridge(nextFridge.id);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const FridgeScreen(),
                          ),
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('냉장고가 삭제되었습니다.')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
