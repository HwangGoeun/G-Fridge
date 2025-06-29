import 'package:flutter/material.dart';
import 'package:g_fridge/screens/add_ingredient_screen.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_cart_provider.dart';
import '../providers/ingredient_provider.dart'; // Import IngredientProvider to add to fridge
import '../providers/fridge_provider.dart'; // Import FridgeProvider
import 'package:uuid/uuid.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  _ShoppingCartScreenState createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('장바구니'),
        actions: [
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
      ),
      body: Container(
        child: Consumer<ShoppingCartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.cartItems.isEmpty) {
              return const Center(
                child: Text('장바구니가 비어있습니다.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 5.0),
              itemCount: cartProvider.cartItems.length,
              itemBuilder: (context, index) {
                final ingredient = cartProvider.cartItems[index];
                return Card(
                  color: Colors.white, // Card color is already white
                  surfaceTintColor: Colors.transparent, // Prevent theme tinting
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            cartProvider.removeItem(ingredient);
                          },
                        ),
                        // Ingredient Name
                        Expanded(
                          child: Text(
                            ingredient.name,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        // Quantity Controls and Display
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 20),
                              onPressed: () {
                                cartProvider.decreaseQuantity(ingredient);
                              },
                            ),
                            SizedBox(
                              width: 30, // Adjust width as needed
                              child: Text(
                                ingredient.quantity.toString(),
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 20),
                              onPressed: () {
                                cartProvider.increaseQuantity(ingredient);
                              },
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.kitchen_outlined), // 냉장고 아이콘
                          onPressed: () {
                            // Add item to current fridge using FridgeProvider
                            final fridgeProvider = Provider.of<FridgeProvider>(
                                context,
                                listen: false);
                            final newIngredient =
                                ingredient.copyWith(id: const Uuid().v4());
                            fridgeProvider
                                .addIngredientToCurrentFridge(newIngredient);
                            cartProvider.removeItem(ingredient);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('${ingredient.name}이 냉장고에 추가되었습니다.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
