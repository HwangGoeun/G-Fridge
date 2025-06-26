import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_ingredient_screen.dart'; // 나중에 생성할 재료 추가 화면 파일
import 'shopping_cart_screen.dart'; // Import shopping cart screen
import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../providers/shopping_cart_provider.dart';
import 'edit_ingredient_screen.dart';

// IngredientCard 위젯 추가
class IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;
  final VoidCallback onCart;

  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
    required this.onCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ingredient.name,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, size: 28),
                    onPressed: onCart,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                ingredient.expirationDate != null
                    ? '${ingredient.expirationDate!.year}/${ingredient.expirationDate!.month.toString().padLeft(2, '0')}/${ingredient.expirationDate!.day.toString().padLeft(2, '0')}'
                    : '유통기한 없음',
                style: const TextStyle(fontSize: 16),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    onPressed: onIncrease,
                  ),
                  Text(
                    ingredient.quantity.toString(),
                    style: const TextStyle(fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 28),
                    onPressed: onDecrease,
                  ),
                ],
              ),
            ],
          )
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
      return ListView.builder(
        padding: const EdgeInsets.only(top: 3.0),
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          final ingredient = ingredients[index];
          final originalIndex = provider.ingredients.indexOf(ingredient);
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
              onIncrease: () => provider.increaseQuantity(originalIndex),
              onDecrease: () => provider.decreaseQuantity(originalIndex),
              onDelete: () => provider.removeIngredient(originalIndex),
              onCart: () {
                final ingredientForCart = Ingredient(
                  name: ingredient.name,
                  storageType: ingredient.storageType,
                  quantity: 1.0, // 수량을 1.0으로 고정
                  expirationDate: null, // 유통기한 null로 설정
                );
                Provider.of<ShoppingCartProvider>(context, listen: false)
                    .addItem(ingredientForCart);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${ingredient.name}이(가) 장바구니에 추가되었습니다.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('G Fridge'),
        actions: [
          // Shopping cart button
          IconButton(
            icon: const Icon(Icons.shopping_cart), // Shopping cart icon
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
