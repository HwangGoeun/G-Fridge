import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:g_fridge/screens/fridge_screen.dart';
import 'package:g_fridge/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:g_fridge/providers/fridge_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Provider.of<FridgeProvider>(context, listen: false).initialize();
          }
        });
        if (snapshot.hasData) {
          return const FridgeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
