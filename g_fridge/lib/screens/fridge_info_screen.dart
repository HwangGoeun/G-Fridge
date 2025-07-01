import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fridge_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FridgeInfoScreen extends StatefulWidget {
  const FridgeInfoScreen({super.key});

  @override
  State<FridgeInfoScreen> createState() => _FridgeInfoScreenState();
}

class _FridgeInfoScreenState extends State<FridgeInfoScreen> {
  bool _editingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final fridge =
        Provider.of<FridgeProvider>(context, listen: false).currentFridge;
    _nameController = TextEditingController(text: fridge?.name ?? '');
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
    final members = fridge?.members ?? [];
    final fridgeId = fridge?.id ?? '';
    final fridgeType = fridge?.type ?? '타입 없음';

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
                        if (!_editingName)
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
                    if (_editingName)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        buttonStyleData: ButtonStyleData(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                        ),
                        items: ['가정용', '사무실용', '기숙사용']
                            .map((type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ))
                            .toList(),
                        value: fridgeType,
                        onChanged: (value) {
                          if (value != null && value != fridgeType) {
                            Provider.of<FridgeProvider>(context, listen: false)
                                .updateFridgeType(fridgeId, value);
                          }
                        },
                        iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
                        ),
                      ),
                    ),
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
                          onPressed: () {
                            final fridge = Provider.of<FridgeProvider>(context,
                                    listen: false)
                                .currentFridge;
                            if (fridge != null) {
                              final shareText =
                                  'G-Fridge에서 [${fridge.name}] 냉장고를 함께 관리해요!\n\n초대 ID: ${fridge.id}';
                              Share.share(shareText);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('냉장고 정보를 불러올 수 없습니다.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('공유 링크 생성'),
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
            // 멤버 카드
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
                          Icon(Icons.group, color: Colors.blue[600]),
                          const SizedBox(width: 10),
                          const Text(
                            '냉장고 멤버 목록',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (members.isEmpty)
                        const Text('멤버가 없습니다.',
                            style: TextStyle(color: Colors.grey)),
                      if (members.isNotEmpty)
                        FutureBuilder<Map<String, String>>(
                          future: () async {
                            Map<String, String> uidToNicknameTag = {};
                            for (final m in members) {
                              if (m['uid'] != null) {
                                final doc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(m['uid'])
                                    .get();
                                final nicknameTag =
                                    doc.data()?['nickname'] ?? '미등록';
                                uidToNicknameTag[m['uid']!] = nicknameTag;
                              }
                            }
                            return uidToNicknameTag;
                          }(),
                          builder: (context, snapshot) {
                            final myUid =
                                FirebaseAuth.instance.currentUser?.uid;
                            final uidToNicknameTag = snapshot.data ?? {};
                            return Column(
                              children: members
                                  .whereType<Map<String, String>>()
                                  .cast<Map<String, String>>()
                                  .map((m) {
                                final uid = m['uid'];
                                final display = uidToNicknameTag[uid] ?? '미등록';
                                final isCreator = fridge?.creatorId != null &&
                                    uid == fridge?.creatorId;
                                final isMe = myUid != null && uid == myUid;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCreator
                                            ? Icons.person
                                            : Icons.person_outline,
                                        size: 20,
                                        color: isCreator
                                            ? Colors.blue[700]
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SelectableText(
                                          display,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87),
                                        ),
                                      ),
                                      if (isMe)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            '나',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (isCreator)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            '생성자',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
