import 'package:flutter/material.dart';
import 'wish_add_screen.dart';
import 'package:provider/provider.dart';
import '../providers/wish_list_provider.dart';
import '../models/ingredient.dart';
import '../providers/shopping_cart_provider.dart';
import '../providers/fridge_provider.dart';
import 'package:uuid/uuid.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  bool _isSelectionMode = false;
  Set<int> _selectedIndexes = {};
  String? _lastFridgeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fridgeProvider = Provider.of<FridgeProvider>(context);
    final wishProvider = Provider.of<WishListProvider>(context, listen: false);
    final fridgeId = fridgeProvider.currentFridgeId;
    if (fridgeId.isNotEmpty && fridgeId != _lastFridgeId) {
      wishProvider.setFridgeId(fridgeId);
      _lastFridgeId = fridgeId;
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIndexes.clear();
      }
    });
  }

  void _toggleSelect(int idx) {
    setState(() {
      if (_selectedIndexes.contains(idx)) {
        _selectedIndexes.remove(idx);
      } else {
        _selectedIndexes.add(idx);
      }
    });
  }

  void _selectAll(int length) {
    setState(() {
      if (_selectedIndexes.length == length) {
        _selectedIndexes.clear();
      } else {
        _selectedIndexes = Set.from(List.generate(length, (i) => i));
      }
    });
  }

  void _batchAddToCart(
      WishListProvider wishProvider, ShoppingCartProvider cartProvider) {
    final selected = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in selected) {
      final wish = wishProvider.wishes[idx];
      final ingredient = Ingredient(
        id: const Uuid().v4(),
        ingredientName: wish.name,
        storageType: StorageType.refrigerated,
        quantity: 1.0,
        expirationDate: null,
      );
      cartProvider.addItem(ingredient);
      wishProvider.removeWish(wish.id);
    }
    setState(() {
      _selectedIndexes.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('장바구니에 추가되었습니다.')),
    );
  }

  void _batchAddToFridge(
      WishListProvider wishProvider, FridgeProvider fridgeProvider) {
    final selected = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in selected) {
      final wish = wishProvider.wishes[idx];
      final ingredient = Ingredient(
        id: const Uuid().v4(),
        ingredientName: wish.name,
        storageType: StorageType.refrigerated,
        quantity: 1.0,
        expirationDate: null,
      );
      fridgeProvider.addIngredientToCurrentFridge(ingredient);
      wishProvider.removeWish(wish.id);
    }
    setState(() {
      _selectedIndexes.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('냉장고에 추가되었습니다.')),
    );
  }

  void _batchDelete(WishListProvider wishProvider) {
    final selected = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in selected) {
      final wish = wishProvider.wishes[idx];
      wishProvider.removeWish(wish.id);
    }
    setState(() {
      _selectedIndexes.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('삭제되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위시리스트'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: Icon(
                    _selectedIndexes.length ==
                                Provider.of<WishListProvider>(context,
                                        listen: false)
                                    .wishes
                                    .length &&
                            Provider.of<WishListProvider>(context,
                                    listen: false)
                                .wishes
                                .isNotEmpty
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  tooltip: '전체 선택',
                  onPressed: () {
                    final wishProvider =
                        Provider.of<WishListProvider>(context, listen: false);
                    _selectAll(wishProvider.wishes.length);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  tooltip: '장바구니에 추가',
                  onPressed: _selectedIndexes.isEmpty
                      ? null
                      : () {
                          final wishProvider = Provider.of<WishListProvider>(
                              context,
                              listen: false);
                          final cartProvider =
                              Provider.of<ShoppingCartProvider>(context,
                                  listen: false);
                          _batchAddToCart(wishProvider, cartProvider);
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.kitchen_outlined),
                  tooltip: '냉장고에 추가',
                  onPressed: _selectedIndexes.isEmpty
                      ? null
                      : () {
                          final wishProvider = Provider.of<WishListProvider>(
                              context,
                              listen: false);
                          final fridgeProvider = Provider.of<FridgeProvider>(
                              context,
                              listen: false);
                          _batchAddToFridge(wishProvider, fridgeProvider);
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '삭제',
                  onPressed: _selectedIndexes.isEmpty
                      ? null
                      : () {
                          final wishProvider = Provider.of<WishListProvider>(
                              context,
                              listen: false);
                          _batchDelete(wishProvider);
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: '취소',
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedIndexes.clear();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.check_box_outline_blank),
                  tooltip: '선택 모드',
                  onPressed: () {
                    _toggleSelectionMode();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WishAddScreen()),
                    );
                  },
                  tooltip: '위시리스트에 재료 추가',
                ),
              ],
      ),
      body: Consumer<WishListProvider>(
        builder: (context, wishProvider, child) {
          if (wishProvider.wishes.isEmpty) {
            return const Center(
              child: Text(
                '위시리스트가 비어 있습니다.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wishProvider.wishes.length,
            itemBuilder: (context, index) {
              final wish = wishProvider.wishes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _isSelectionMode
                      ? Checkbox(
                          value: _selectedIndexes.contains(index),
                          onChanged: (_) => _toggleSelect(index),
                        )
                      : null,
                  title: Text(wish.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: wish.reason.isNotEmpty ? Text(wish.reason) : null,
                  trailing: !_isSelectionMode ? null : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
