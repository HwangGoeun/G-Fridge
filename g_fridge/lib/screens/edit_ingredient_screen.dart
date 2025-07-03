import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../providers/shopping_cart_provider.dart';
import '../providers/fridge_provider.dart';

class EditIngredientScreen extends StatefulWidget {
  final Ingredient ingredient;
  const EditIngredientScreen({super.key, required this.ingredient});

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
    _nameController.text = widget.ingredient.ingredientName;
    _quantity = widget.ingredient.quantity;
    _selectedStorageType = widget.ingredient.storageType;
    _selectedExpirationDate = widget.ingredient.expirationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateIngredient() {
    if (_formKey.currentState!.validate()) {
      final updatedIngredient = widget.ingredient.copyWith(
        ingredientName: _nameController.text,
        quantity: _quantity,
        storageType: _selectedStorageType,
        expirationDate: _selectedExpirationDate,
      );

      Provider.of<IngredientProvider>(context, listen: false)
          .updateIngredient(updatedIngredient);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('재료가 수정되었습니다!'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('재료 수정하기'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // 재료 이름 입력 카드
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '재료 이름을 입력하세요',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '재료 이름을 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              // 수량 입력 카드
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.scale_outlined, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            '수량',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  if (_quantity > 0.5) _quantity -= 0.5;
                                });
                              },
                            ),
                          ),
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              _quantity.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  _quantity += 0.5;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 보관 방식 선택 카드
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storage_outlined, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            '보관 방식',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: StorageType.values.map((type) {
                          bool isSelected = _selectedStorageType == type;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedStorageType = type;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? Colors.blue[600]
                                      : Colors.grey[100],
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _storageTypeLabels[type]!,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // 유통기한 선택 카드
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            '유통기한',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedExpirationDate == null
                                  ? '날짜를 선택하세요'
                                  : '${_selectedExpirationDate!.year}-${_selectedExpirationDate!.month.toString().padLeft(2, '0')}-${_selectedExpirationDate!.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedExpirationDate == null
                                    ? Colors.grey[500]
                                    : Colors.grey[700],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedExpirationDate ?? now,
                                  firstDate: DateTime(now.year - 1),
                                  lastDate: DateTime(now.year + 5),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedExpirationDate = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_month),
                              label: const Text('선택'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 버튼들
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _updateIngredient,
                  icon: const Icon(Icons.save),
                  label: const Text('수정하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              // 재료 삭제하기 버튼
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red[600], size: 28),
                            const SizedBox(width: 8),
                            const Text('재료 삭제',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        content: const Text(
                          '정말로 이 재료를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
                          style: TextStyle(fontSize: 16),
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          SizedBox(
                            width: 100,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[600],
                                side: BorderSide(color: Colors.blue[600]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('취소',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('삭제',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final fridgeProvider =
                          Provider.of<FridgeProvider>(context, listen: false);
                      fridgeProvider.removeIngredientFromCurrentFridge(
                          widget.ingredient.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('재료가 삭제되었습니다!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('재료 삭제하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
