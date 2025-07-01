import 'package:flutter/material.dart';

class FridgeListScreen extends StatelessWidget {
  const FridgeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 냉장고 목록 데이터 (나중에 실제 데이터로 교체 가능)
    final List<Map<String, dynamic>> fridges = [
      {
        'name': '우리집 냉장고',
        'type': '개인용',
        'ingredientCount': 12,
      },
      {
        'name': '회사 냉장고',
        'type': '개인용',
        'ingredientCount': 8,
      },
      {
        'name': '기숙사 냉장고',
        'type': '개인용',
        'ingredientCount': 15,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('나의 냉장고'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: fridges.length,
        itemBuilder: (context, index) {
          final fridge = fridges[index];
          return Container(
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.kitchen,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              title: Text(
                fridge['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${fridge['type']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '재료 ${fridge['ingredientCount']}개',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
              onTap: () {
                // 냉장고 선택 시 메인 화면으로 돌아가기
                Navigator.pop(context, fridge['name']);
              },
            ),
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // 새 냉장고 추가 기능 (나중에 구현)
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('새 냉장고 추가 기능은 준비 중입니다.'),
      //         duration: Duration(seconds: 2),
      //       ),
      //     );
      //   },
      //   backgroundColor: Colors.blue[600],
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }
}
