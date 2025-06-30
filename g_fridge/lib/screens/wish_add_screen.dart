import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wish.dart';
import '../providers/wish_list_provider.dart';

class WishAddScreen extends StatefulWidget {
  const WishAddScreen({super.key});

  @override
  State<WishAddScreen> createState() => _WishAddScreenState();
}

class _WishAddScreenState extends State<WishAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _saveWish() {
    if (_formKey.currentState!.validate()) {
      final wish = Wish(
        name: _nameController.text.trim(),
        reason: _reasonController.text.trim(),
      );
      Provider.of<WishListProvider>(context, listen: false).addWish(wish);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위시리스트에 추가되었습니다!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위시리스트 재료 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '재료 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '재료 이름을 입력하세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: '필요한 이유',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveWish,
                icon: const Icon(Icons.favorite_border),
                label: const Text('위시리스트에 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
