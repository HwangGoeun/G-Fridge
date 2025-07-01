import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider 패키지 임포트
import 'screens/fridge_screen.dart'; // 나중에 생성할 메인 냉장고 화면 파일
import 'providers/ingredient_provider.dart'; // IngredientProvider 임포트
import 'providers/shopping_cart_provider.dart'; // Import the new provider
import 'providers/fridge_provider.dart'; // Import FridgeProvider
import 'providers/wish_list_provider.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
        useMaterial3: true,
        primaryColor: const Color(0xFF2196F3),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          headerBackgroundColor: Colors.blue[600],
          headerForegroundColor: Colors.white,
          dayForegroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.black87;
          }),
          dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.blue[600];
            }
            return Colors.transparent;
          }),
        ),
      ),
      home: const FridgeScreen(),
    );
  }
}
