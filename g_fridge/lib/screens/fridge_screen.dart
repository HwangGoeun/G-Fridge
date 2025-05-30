import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_ingredient_screen.dart'; // 나중에 생성할 재료 추가 화면 파일
import 'shopping_cart_screen.dart'; // Import shopping cart screen
import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';

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
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          final ingredient = ingredients[index];
          final originalIndex = provider.ingredients.indexOf(ingredient);
          return ListTile(
            title: Flexible(
              child: Text(
                ingredient.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () {
                    provider.decreaseQuantity(originalIndex);
                  },
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${ingredient.quantity}개',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () {
                    provider.increaseQuantity(originalIndex);
                  },
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {
                    provider.removeIngredient(originalIndex);
                  },
                  color: Colors.grey,
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientProvider = Provider.of<IngredientProvider>(context);
    final refrigeratedIngredients = ingredientProvider.ingredients
        .where(
            (ingredient) => ingredient.storageType == StorageType.refrigerated)
        .toList();
    final frozenIngredients = ingredientProvider.ingredients
        .where((ingredient) => ingredient.storageType == StorageType.frozen)
        .toList();
    final roomTemperatureIngredients = ingredientProvider.ingredients
        .where((ingredient) =>
            ingredient.storageType == StorageType.roomTemperature)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gordon Fridge'),
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
