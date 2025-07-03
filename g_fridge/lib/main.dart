import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider 패키지 임포트
import 'providers/ingredient_provider.dart'; // IngredientProvider 임포트
import 'providers/shopping_cart_provider.dart'; // Import the new provider
import 'providers/fridge_provider.dart'; // Import FridgeProvider
import 'providers/wish_list_provider.dart';
import 'screens/auth_wrapper.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IngredientProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingCartProvider()),
        ChangeNotifierProvider(create: (_) => FridgeProvider()),
        ChangeNotifierProvider(create: (_) => WishListProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'G Fridge',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
