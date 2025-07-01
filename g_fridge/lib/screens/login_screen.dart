import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../providers/fridge_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      if (googleAuth?.accessToken != null && googleAuth?.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

        // Once signed in, return the UserCredential
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        // 닉네임 없으면 생성 및 저장
        final user = userCredential.user;
        if (user != null) {
          final fridgeProvider =
              Provider.of<FridgeProvider>(context, listen: false);
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final nickname = userDoc.data()?['nickname'];
          if (!userDoc.exists) {
            // Generate nickname#tag and save only for new users
            await fridgeProvider.addOrUpdateMyMemberWithUniqueTag(
                fridgeProvider.generateDefaultNickname());
            final fridge = fridgeProvider.currentFridge;
            final myMember =
                fridge?.members.whereType<Map<String, String>>().firstWhere(
                      (m) => m['uid'] == user.uid,
                      orElse: () => {},
                    );
            if (myMember != null &&
                myMember.isNotEmpty &&
                myMember['nickname'] != null &&
                myMember['tag'] != null) {
              final nicknameWithTag =
                  "${myMember['nickname']}#${myMember['tag']}";
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({'nickname': nicknameWithTag}, SetOptions(merge: true));
            }
            // 신규 유저는 냉장고/멤버 정보도 바로 fetch
            await fridgeProvider.initializeFromFirestore();
          }
          await fridgeProvider.loadMyNicknameWithTag();
        }
        // 로그인 성공 후 화면 닫기
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: _isLoading
            ? const SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black54),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: _signInWithGoogle,
                child: const Text('Sign in with Google'),
              ),
      ),
    );
  }
}

class GoogleAuthHelper {
  static Future<void> signInWithGoogle(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      if (googleAuth?.accessToken != null && googleAuth?.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        // 닉네임 없으면 생성 및 저장
        final user = userCredential.user;
        if (user != null) {
          final fridgeProvider =
              Provider.of<FridgeProvider>(context, listen: false);
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final nickname = userDoc.data()?['nickname'];
          if (!userDoc.exists) {
            // Generate nickname#tag and save only for new users
            await fridgeProvider.addOrUpdateMyMemberWithUniqueTag(
                fridgeProvider.generateDefaultNickname());
            final fridge = fridgeProvider.currentFridge;
            final myMember =
                fridge?.members.whereType<Map<String, String>>().firstWhere(
                      (m) => m['uid'] == user.uid,
                      orElse: () => {},
                    );
            if (myMember != null &&
                myMember.isNotEmpty &&
                myMember['nickname'] != null &&
                myMember['tag'] != null) {
              final nicknameWithTag =
                  "${myMember['nickname']}#${myMember['tag']}";
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({'nickname': nicknameWithTag}, SetOptions(merge: true));
            }
            // 신규 유저는 냉장고/멤버 정보도 바로 fetch
            await fridgeProvider.initializeFromFirestore();
          }
          await fridgeProvider.loadMyNicknameWithTag();
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google: $e'),
        ),
      );
    }
  }
}
