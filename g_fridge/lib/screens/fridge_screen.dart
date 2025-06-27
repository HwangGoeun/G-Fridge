import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_ingredient_screen.dart'; // 나중에 생성할 재료 추가 화면 파일
import 'shopping_cart_screen.dart'; // Import shopping cart screen
import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../providers/shopping_cart_provider.dart';
import 'edit_ingredient_screen.dart';
import 'package:uuid/uuid.dart';

// IngredientCard 위젯 추가
class IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onDelete;
  final VoidCallback onCart;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isInCart; // 장바구니에 추가된 상태

  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.onDelete,
    required this.onCart,
    required this.onIncrease,
    required this.onDecrease,
    this.isInCart = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AspectRatio(
      aspectRatio: 0.6,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size.width * 0.045),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: size.width * 0.01,
                  blurRadius: size.width * 0.02,
                  offset: Offset(0, size.height * 0.002),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.006,
              ),
              child: Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: size.width * 0.05,
                    bottom: size.width * 0.01,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.kitchen,
                          size: size.width * 0.15, color: Colors.orangeAccent),
                      SizedBox(height: size.height * 0.015),
                      SizedBox(
                        width: size.width * 0.32,
                        child: Text(
                          ingredient.name,
                          style: TextStyle(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: size.height * 0.004),
                      SizedBox(
                        width: size.width * 0.37,
                        child: Text(
                          ingredient.expirationDate != null
                              ? '${ingredient.expirationDate!.year}년 ${ingredient.expirationDate!.month}월 ${ingredient.expirationDate!.day}일'
                              : '소비기한을 입력하세요',
                          style: TextStyle(
                              fontSize: size.width * 0.032, color: Colors.grey),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.remove_circle_outline,
                                color: Colors.grey, size: size.width * 0.06),
                            onPressed: ingredient.quantity == 0.5
                                ? onDelete
                                : onDecrease,
                          ),
                          SizedBox(
                            child: Text(
                              ingredient.quantity.toString(),
                              style: TextStyle(
                                  fontSize: size.width * 0.045,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.add_circle_outline,
                                color: Colors.grey, size: size.width * 0.06),
                            onPressed: onIncrease,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (ingredient.quantity == 0.5)
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                icon: Icon(
                  isInCart ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  color: isInCart ? Colors.green : Colors.grey,
                  size: size.width * 0.06,
                ),
                onPressed: () {
                  if (isInCart) {
                    Provider.of<ShoppingCartProvider>(context, listen: false)
                        .removeItem(ingredient);
                  } else {
                    onCart();
                  }
                },
                splashRadius: size.width * 0.06,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isInCart ? '장바구니에서 제거' : '장바구니에 추가',
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(Icons.close,
                  color: Colors.grey, size: size.width * 0.06),
              onPressed: onDelete,
              splashRadius: size.width * 0.06,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: '재료 삭제',
            ),
          ),
        ],
      ),
    );
  }
}

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to build ingredient list view
  Widget _buildIngredientListView(List<Ingredient> ingredients,
      IngredientProvider provider, String emptyMessage) {
    if (ingredients.isEmpty) {
      return Center(child: Text(emptyMessage));
    } else {
      return GridView.builder(
        padding:
            const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          // 재료 카드 간 간격 조정
          mainAxisSpacing: 4,
          childAspectRatio: 0.78,
        ),
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          final ingredient = ingredients[index];
          final originalIndex = provider.ingredients.indexOf(ingredient);
          final cartProvider = Provider.of<ShoppingCartProvider>(context);
          final isInCart =
              cartProvider.cartItems.any((item) => item.id == ingredient.id);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditIngredientScreen(
                      ingredient: ingredient, ingredientIndex: originalIndex),
                ),
              );
            },
            child: IngredientCard(
              ingredient: ingredient,
              onDelete: () => provider.removeIngredient(originalIndex),
              onIncrease: () => provider.increaseQuantity(originalIndex),
              onDecrease: () => provider.decreaseQuantity(originalIndex),
              onCart: () {
                final ingredientForCart = ingredient.copyWith(quantity: 1.0);
                Provider.of<ShoppingCartProvider>(context, listen: false)
                    .addItem(ingredientForCart);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${ingredient.name}이(가) 장바구니에 추가되었습니다.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              isInCart: isInCart,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientProvider = Provider.of<IngredientProvider>(context);

    // 유통기한 정렬 함수
    int compareIngredients(Ingredient a, Ingredient b) {
      if (a.expirationDate == null && b.expirationDate == null) {
        return 0; // 둘 다 유통기한 없으면 순서 유지
      }
      if (a.expirationDate == null) {
        return 1; // a만 유통기한 없으면 b가 앞으로
      }
      if (b.expirationDate == null) {
        return -1; // b만 유통기한 없으면 a가 앞으로
      }
      return a.expirationDate!.compareTo(b.expirationDate!); // 둘 다 있으면 날짜 비교
    }

    final refrigeratedIngredients = ingredientProvider.ingredients
        .where(
            (ingredient) => ingredient.storageType == StorageType.refrigerated)
        .toList()
      ..sort(compareIngredients);
    final frozenIngredients = ingredientProvider.ingredients
        .where((ingredient) => ingredient.storageType == StorageType.frozen)
        .toList()
      ..sort(compareIngredients);
    final roomTemperatureIngredients = ingredientProvider.ingredients
        .where((ingredient) =>
            ingredient.storageType == StorageType.roomTemperature)
        .toList()
      ..sort(compareIngredients);

    return Scaffold(
      backgroundColor: Colors.grey[100], // 배경색을 더 밝은 회색으로
      appBar: AppBar(
        title: const Text('G Fridge'),
        actions: [
          // Shopping cart button
          IconButton(
            icon:
                const Icon(Icons.shopping_cart_outlined), // Shopping cart icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const ShoppingCartScreen()), // Navigate to shopping cart screen
              );
            },
            tooltip: '장바구니',
          ),
          // Add ingredient button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddIngredientScreen()),
              );
            },
            tooltip: '재료 추가',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '냉장'),
            Tab(text: '냉동'),
            Tab(text: '실온'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Refrigerated Ingredients View
          _buildIngredientListView(
              refrigeratedIngredients, ingredientProvider, '냉장 재료가 없습니다.'),

          // Frozen Ingredients View
          _buildIngredientListView(
              frozenIngredients, ingredientProvider, '냉동 재료가 없습니다.'),

          // Room Temperature Ingredients View
          _buildIngredientListView(
              roomTemperatureIngredients, ingredientProvider, '실온 재료가 없습니다.'),
        ],
      ),
    );
  }
}
