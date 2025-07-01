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
      print('[LoginScreen] 구글 로그인 시도');
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
        print('[LoginScreen] 구글 로그인 성공');
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
            final defaultNickname = fridgeProvider.generateDefaultNickname();
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'nickname': defaultNickname}, SetOptions(merge: true));
            print('[LoginScreen] 신규 유저 닉네임 생성');
            await fridgeProvider.initializeFromFirestore();
          }
          print('[LoginScreen] FridgeProvider 초기화 시작');
          await fridgeProvider.initialize();
          await fridgeProvider.initializeFromFirestore();
          print('[LoginScreen] FridgeProvider 초기화 완료');
          await fridgeProvider.loadMyNickname();
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeidth = MediaQuery.of(context).size.height;
    final logoSize = screenWidth * 0.08;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isLoading
            ? const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black54),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.kitchen,
                      size: screenHeidth * 0.16, color: Colors.blue[600]),
                  SizedBox(height: screenHeidth * 0.01),
                  Text(
                    'FRIENDGE',
                    style: TextStyle(
                      fontSize: screenHeidth * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  const Text(
                    '함께 채우는 냉장고, 프렌지',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  SizedBox(height: screenHeidth * 0.05),
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        elevation: 2,
                      ).copyWith(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                      ),
                      onPressed: _signInWithGoogle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/google_logo.png',
                            height: 23,
                            width: 23,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          const Text(
                            '구글로 로그인하기',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
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
            final defaultNickname = fridgeProvider.generateDefaultNickname();
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'nickname': defaultNickname}, SetOptions(merge: true));
            await fridgeProvider.initializeFromFirestore();
          }
          await fridgeProvider.loadMyNickname();
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
