import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../providers/shopping_cart_provider.dart';

class AddIngredientScreen extends StatefulWidget {
  const AddIngredientScreen({super.key});

  @override
  State<AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  double _quantity = 1.0;
  StorageType _selectedStorageType = StorageType.refrigerated;

  // Map StorageType to Korean text
  final Map<StorageType, String> _storageTypeLabels = {
    StorageType.refrigerated: '냉장',
    StorageType.frozen: '냉동',
    StorageType.roomTemperature: '실온',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addIngredientToCart() {
    if (_formKey.currentState!.validate()) {
      final newIngredient = Ingredient(
        name: _nameController.text,
        quantity: _quantity,
        storageType: _selectedStorageType,
      );

      // Add ingredient to shopping cart using the provider
      Provider.of<ShoppingCartProvider>(context, listen: false)
          .addItem(newIngredient);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('장바구니에 추가되었습니다!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Optionally navigate back or clear the form
      // Navigator.pop(context);
      _nameController.clear();
      setState(() {
        _quantity = 1.0;
        _selectedStorageType = StorageType.refrigerated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('재료 추가하기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '재료 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '재료 이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Quantity Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('수량:', style: TextStyle(fontSize: 16)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            if (_quantity > 0.5) _quantity -= 0.5;
                          });
                        },
                      ),
                      Container(
                        width: 50, // Fixed width for quantity display
                        alignment: Alignment.center,
                        child: Text(
                          _quantity.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            _quantity += 0.5;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Storage Type Selection
              const Text('보관 방식:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: StorageType.values.map((type) {
                  bool isSelected = _selectedStorageType == type;
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedStorageType = type;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[100],
                      foregroundColor:
                          isSelected ? Colors.white : Colors.black87,
                    ),
                    child: Text(_storageTypeLabels[type]!),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              // Add to Shopping Cart Button
              ElevatedButton(
                onPressed: _addIngredientToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('장바구니에 추가하기'),
              ),
              // The existing '냉장고에 추가하기' button can remain if needed for direct fridge addition
              // If not, you can remove the AddIngredient method and this button.
              // For now, let's keep both options.
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Existing logic to add to fridge
                  if (_formKey.currentState!.validate()) {
                    final newIngredient = Ingredient(
                      name: _nameController.text,
                      quantity: _quantity,
                      storageType: _selectedStorageType,
                    );
                    Provider.of<IngredientProvider>(context, listen: false)
                        .addIngredient(newIngredient);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('냉장고에 추가되었습니다!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    _nameController.clear();
                    setState(() {
                      _quantity = 0.5;
                      _selectedStorageType = StorageType.refrigerated;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('냉장고에 추가하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
