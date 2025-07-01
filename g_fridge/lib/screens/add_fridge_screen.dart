import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fridge_provider.dart';
import '../models/fridge.dart';

class AddFridgeScreen extends StatefulWidget {
  const AddFridgeScreen({super.key});

  @override
  State<AddFridgeScreen> createState() => _AddFridgeScreenState();
}

class _AddFridgeScreenState extends State<AddFridgeScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addFridge() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('냉장고 이름을 입력하세요.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<FridgeProvider>(context, listen: false);
      final newFridge = Fridge(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        type: '개인용',
        creatorId: '',
      );
      await provider.addFridge(newFridge);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('냉장고 추가에 실패했습니다: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = screenHeight * 0.12;
    final buttonWidth = screenWidth * 0.7;
    return Scaffold(
      appBar: AppBar(title: const Text('냉장고 추가')),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.kitchen, size: iconSize, color: Colors.blue[600]),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'FRIENDGE',
                style: TextStyle(
                  fontSize: screenHeight * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              const Text(
                '새로운 냉장고를 만들어보세요!',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: screenHeight * 0.04),
              SizedBox(
                width: buttonWidth,
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '냉장고 이름',
                    hintText: '예) 우리집 냉장고',
                  ),
                  enabled: !_isSaving,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              SizedBox(
                width: buttonWidth,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSaving ? null : _addFridge,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('냉장고 추가',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
