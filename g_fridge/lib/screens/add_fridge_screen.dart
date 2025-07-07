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
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isSaving = false;

  // 모드: 선택, 냉장고 추가, 초대코드 입력
  AddFridgeMode _mode = AddFridgeMode.select;

  @override
  void dispose() {
    _nameController.dispose();
    _inviteCodeController.dispose();
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

  Future<void> _joinByInviteCode() async {
    final inviteCode = _inviteCodeController.text.trim();
    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초대코드를 입력하세요.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<FridgeProvider>(context, listen: false);
      final result = await provider.joinFridgeByCode(inviteCode);
      final resultType = result['result'];
      final message = result['message'] ?? '알 수 없는 오류입니다.';
      if (resultType == 'success') {
        await provider.initializeFromFirestore();
        if (context.mounted) Navigator.pop(context, true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('참여에 실패했습니다: $e')),
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
              SizedBox(
                width: 300,
                child: Image.asset('assets/friendge_1_short.png'),
              ),
              SizedBox(height: screenWidth * 0.02),
              const Text(
                '새로운 냉장고를 만들어보세요!',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: screenHeight * 0.04),
              if (_mode == AddFridgeMode.select) ...[
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
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() => _mode = AddFridgeMode.add);
                          },
                    child: const Text('새로운 냉장고 추가하기',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                SizedBox(
                  width: buttonWidth,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      side: BorderSide(color: Colors.blue[600]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() => _mode = AddFridgeMode.invite);
                          },
                    child: const Text('초대코드 입력',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else if (_mode == AddFridgeMode.add) ...[
                SizedBox(
                  width: buttonWidth,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      hintText: '예) 우리집 냉장고',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    enabled: !_isSaving,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: buttonWidth * 0.45,
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
                            : const Text('확인',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: buttonWidth * 0.1),
                    SizedBox(
                      width: buttonWidth * 0.45,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[600],
                          side: BorderSide(color: Colors.blue[600]!, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() => _mode = AddFridgeMode.select);
                              },
                        child: const Text('뒤로',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ] else if (_mode == AddFridgeMode.invite) ...[
                SizedBox(
                  width: buttonWidth,
                  child: TextField(
                    controller: _inviteCodeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      hintText: '공유 냉장고에 참여하려면 입력',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    enabled: !_isSaving,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: buttonWidth * 0.45,
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
                        onPressed: _isSaving ? null : _joinByInviteCode,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('확인',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: buttonWidth * 0.1),
                    SizedBox(
                      width: buttonWidth * 0.45,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[600],
                          side: BorderSide(color: Colors.blue[600]!, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() => _mode = AddFridgeMode.select);
                              },
                        child: const Text('뒤로',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// 모드 enum 정의
enum AddFridgeMode { select, add, invite }
