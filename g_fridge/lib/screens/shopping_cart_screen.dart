import 'package:flutter/material.dart';
import 'package:g_fridge/screens/add_ingredient_screen.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_cart_provider.dart';
import '../providers/ingredient_provider.dart'; // Import IngredientProvider to add to fridge
import '../providers/fridge_provider.dart'; // Import FridgeProvider
import 'package:uuid/uuid.dart';

class ShoppingCartScreen extends StatefulWidget {
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String id)? onToggleSelect;
  const ShoppingCartScreen({
    super.key,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelect,
  });

  @override
  _ShoppingCartScreenState createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: null, // AppBar는 상위에서 관리
      body: Consumer<ShoppingCartProvider>(
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
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // 삭제 or 체크박스
                      if (widget.selectionMode)
                        Checkbox(
                          value: widget.selectedIds.contains(ingredient.id),
                          onChanged: (_) =>
                              widget.onToggleSelect?.call(ingredient.id),
                          visualDensity: VisualDensity.compact,
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            cartProvider.removeItem(ingredient.id);
                          },
                        ),
                      // 이름
                      Expanded(
                        child: Text(
                          ingredient.ingredientName,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // 수량 조절
                      if (!widget.selectionMode)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 20),
                              onPressed: () {
                                cartProvider.decreaseQuantity(ingredient.id);
                              },
                            ),
                            SizedBox(
                              width: 30,
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
                                cartProvider.increaseQuantity(ingredient.id);
                              },
                            ),
                          ],
                        ),
                      // 냉장고 추가 버튼 (선택 모드 아닐 때만)
                      if (!widget.selectionMode)
                        IconButton(
                          icon: const Icon(Icons.kitchen_outlined),
                          onPressed: () {
                            final fridgeProvider = Provider.of<FridgeProvider>(
                                context,
                                listen: false);
                            final newIngredient = ingredient.copyWith(
                                id: const Uuid().v4(), expirationDate: null);
                            fridgeProvider
                                .addIngredientToCurrentFridge(newIngredient);
                            cartProvider.removeItem(ingredient.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${ingredient.ingredientName}이 냉장고에 추가되었습니다.'),
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
    );
  }
}
