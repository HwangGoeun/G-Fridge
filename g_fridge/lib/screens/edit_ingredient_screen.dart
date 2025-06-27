import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../providers/shopping_cart_provider.dart';

class EditIngredientScreen extends StatefulWidget {
  final Ingredient ingredient;
  final int ingredientIndex;
  const EditIngredientScreen(
      {super.key, required this.ingredient, required this.ingredientIndex});

  @override
  State<EditIngredientScreen> createState() => _EditIngredientScreenState();
}

class _EditIngredientScreenState extends State<EditIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  double _quantity = 1.0;
  StorageType _selectedStorageType = StorageType.refrigerated;
  DateTime? _selectedExpirationDate;

  // Map StorageType to Korean text
  final Map<StorageType, String> _storageTypeLabels = {
    StorageType.refrigerated: '냉장',
    StorageType.frozen: '냉동',
    StorageType.roomTemperature: '실온',
  };

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.ingredient.name;
    _quantity = widget.ingredient.quantity;
    _selectedStorageType = widget.ingredient.storageType;
    _selectedExpirationDate = widget.ingredient.expirationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 유통기한 선택 위젯
  Widget _buildExpirationDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('유통기한:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedExpirationDate == null
                    ? '날짜를 선택하세요'
                    : '${_selectedExpirationDate!.year}-${_selectedExpirationDate!.month.toString().padLeft(2, '0')}-${_selectedExpirationDate!.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedExpirationDate ?? now,
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) {
                  setState(() {
                    _selectedExpirationDate = picked;
                  });
                }
              },
              child: const Text('날짜 선택'),
            ),
          ],
        ),
      ],
    );
  }

  void _addIngredientToCart() {
    if (_formKey.currentState!.validate()) {
      final newIngredient = Ingredient(
        id: widget.ingredient.id,
        name: _nameController.text,
        quantity: _quantity,
        storageType: _selectedStorageType,
        expirationDate: _selectedExpirationDate, // nullable 허용
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
        _selectedExpirationDate = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('재료 수정하기'),
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
              const SizedBox(height: 20),
              // 유통기한 입력
              _buildExpirationDatePicker(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updatedIngredient = Ingredient(
                      id: widget.ingredient.id,
                      name: _nameController.text,
                      quantity: _quantity,
                      storageType: _selectedStorageType,
                      expirationDate: _selectedExpirationDate,
                    );
                    Provider.of<IngredientProvider>(context, listen: false)
                        .updateIngredient(
                            widget.ingredient.id, updatedIngredient);
                    Navigator.pop(context); // 수정 후 화면 닫기
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('수정 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
