import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fridge_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart';
import 'fridge_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});
  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool _isEditing = false;
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Consumer<FridgeProvider>(
      builder: (context, fridgeProvider, _) {
        if (!fridgeProvider.isUserReady) {
          if (user == null) {
            // 로그인 안 한 상태: 로그인 버튼만 표시
            return Scaffold(
              appBar: AppBar(title: const Text('마이페이지')),
              body: Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await GoogleAuthHelper.signInWithGoogle(context);
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('로그인'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            );
          } else {
            // 로그인은 했지만 닉네임 준비 전: 인디케이터
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        }
        final nicknameWithTag =
            fridgeProvider.getMyNicknameWithTag() ?? '닉네임 없음';
        String nickname = nicknameWithTag;
        String tag = '';
        if (nicknameWithTag.contains('#')) {
          final parts = nicknameWithTag.split('#');
          nickname = parts[0];
          tag = parts.length > 1 ? parts[1] : '';
        }
        if (!_isEditing) {
          _nicknameController.text = nickname;
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('마이페이지'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 구글 회원 정보
                if (user != null) ...[
                  if (user.photoURL != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.photoURL!),
                      radius: 36,
                    ),
                  const SizedBox(height: 16),
                  Text(user.displayName ?? '이름 없음',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user.email ?? '이메일 없음',
                      style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  const SizedBox(height: 24),
                ],
                // 닉네임
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('닉네임: ', style: TextStyle(fontSize: 16)),
                    if (user == null)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text('로그인 필요',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      )
                    else if (_isEditing)
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _nicknameController,
                          autofocus: true,
                          enabled: !_isSaving && fridgeProvider.isUserReady,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                    else
                      Text(nickname,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    // 태그는 항상 읽기 전용으로 옆에 표시
                    if (tag.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('#$tag',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue)),
                      ),
                    const SizedBox(width: 8),
                    if (user != null)
                      _isEditing
                          ? IconButton(
                              icon: const Icon(Icons.check, color: Colors.blue),
                              onPressed: (!fridgeProvider.isUserReady ||
                                      _isSaving)
                                  ? null
                                  : () async {
                                      final newNickname =
                                          _nicknameController.text.trim();
                                      print('이전 닉네임: $nickname');
                                      print('변경된 닉네임: $newNickname');
                                      if (newNickname.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('닉네임은 공백일 수 없습니다.')),
                                        );
                                        return;
                                      }
                                      if (!RegExp(
                                              r'^[^\s!@#\$%^&*(),.?":{}|<>\[\]/;`~=_+]+$')
                                          .hasMatch(newNickname)) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  '닉네임에 특수문자나 공백을 사용할 수 없습니다.')),
                                        );
                                        return;
                                      }
                                      setState(() => _isSaving = true);
                                      final fridgeProvider =
                                          Provider.of<FridgeProvider>(context,
                                              listen: false);
                                      final error = await fridgeProvider
                                          .addOrUpdateMyMemberWithUniqueTag(
                                              newNickname);
                                      if (error != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(error)),
                                        );
                                        setState(() => _isSaving = false);
                                        return;
                                      }
                                      setState(() {
                                        _isEditing = false;
                                        _isSaving = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('닉네임이 변경되었습니다.')),
                                      );
                                    },
                            )
                          : IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 20, color: Colors.blue),
                              onPressed:
                                  (!fridgeProvider.isUserReady || _isSaving)
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditing = true;
                                            _nicknameController.text = nickname;
                                          });
                                        },
                            ),
                  ],
                ),
                const SizedBox(height: 32),
                // 로그인/로그아웃 버튼
                if (user != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      Provider.of<FridgeProvider>(context, listen: false)
                          .clear();
                      await FirebaseAuth.instance.signOut();
                      try {
                        await GoogleSignIn().disconnect();
                      } catch (_) {}
                      if (context.mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('로그아웃'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (user != null) const SizedBox(height: 16),
                if (user != null)
                  ElevatedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('회원 탈퇴'),
                                content: const Text(
                                    '정말로 회원 탈퇴하시겠습니까? 모든 데이터가 삭제됩니다.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('취소')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('탈퇴')),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            setState(() => _isSaving = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                // Firestore 데이터 삭제 (users/{uid}, fridges, ingredients, members)
                                final userDoc = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid);
                                final fridgesSnapshot =
                                    await userDoc.collection('fridges').get();
                                for (final fridgeDoc in fridgesSnapshot.docs) {
                                  // 재료 삭제
                                  final ingredientsSnapshot = await fridgeDoc
                                      .reference
                                      .collection('ingredients')
                                      .get();
                                  for (final ingDoc
                                      in ingredientsSnapshot.docs) {
                                    await ingDoc.reference.delete();
                                  }
                                  // 멤버 삭제
                                  final membersSnapshot = await fridgeDoc
                                      .reference
                                      .collection('members')
                                      .get();
                                  for (final memDoc in membersSnapshot.docs) {
                                    await memDoc.reference.delete();
                                  }
                                  // 냉장고 문서 삭제
                                  await fridgeDoc.reference.delete();
                                }
                                // users/{uid} 문서 삭제
                                await userDoc.delete();
                                // Firebase Auth 계정 삭제
                                await user.delete();
                                // Google 계정 세션도 완전히 해제
                                try {
                                  await GoogleSignIn().disconnect();
                                } catch (_) {}
                                try {
                                  await GoogleSignIn().signOut();
                                } catch (_) {}
                                Provider.of<FridgeProvider>(context,
                                        listen: false)
                                    .clear();
                                if (context.mounted) {
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('회원 탈퇴에 실패했습니다: $e')),
                              );
                            } finally {
                              setState(() => _isSaving = false);
                            }
                          },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('회원 탈퇴'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
