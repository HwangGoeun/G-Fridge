import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider 패키지 임포트
import 'screens/fridge_screen.dart'; // 나중에 생성할 메인 냉장고 화면 파일
import 'providers/ingredient_provider.dart'; // IngredientProvider 임포트
import 'providers/shopping_cart_provider.dart'; // Import the new provider

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider를 사용하여 IngredientProvider를 제공합니다.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => IngredientProvider()),
        ChangeNotifierProvider(
            create: (context) =>
                ShoppingCartProvider()), // Add ShoppingCartProvider here
      ],
      child: MaterialApp(
        title: 'G Fridge',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
          useMaterial3: true,
          primaryColor: Colors.grey,
        ),
        home: const FridgeScreen(), // 앱 시작 시 보여줄 화면
      ),
    );
  }
}
