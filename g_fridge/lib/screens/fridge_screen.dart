import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_ingredient_screen.dart'; // 나중에 생성할 재료 추가 화면 파일
import 'shopping_cart_screen.dart'; // Import shopping cart screen
import 'fridge_list_screen.dart'; // Import fridge list screen
import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../providers/shopping_cart_provider.dart';
import '../providers/fridge_provider.dart'; // Import FridgeProvider
import 'edit_ingredient_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'fridge_info_screen.dart'; // 냉장고 정보 화면 import
import 'wish_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_page_screen.dart';
import 'add_fridge_screen.dart';

// GoogleAuthHelper는 login_screen.dart에서 import됨

// IngredientCard 위젯 추가
class IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onDelete;
  final VoidCallback onCart;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isInCart;
  final bool selectionMode;
  final bool checked;
  final VoidCallback? onCheckChanged;

  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.onDelete,
    required this.onCart,
    required this.onIncrease,
    required this.onDecrease,
    this.isInCart = false,
    this.selectionMode = false,
    this.checked = false,
    this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.045),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: size.width * 0.01,
            blurRadius: size.width * 0.02,
            offset: Offset(0, size.height * 0.002),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: size.width * 0.13),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: size.width * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: size.width * 0.75,
                            child: Text(
                              ingredient.name,
                              style: TextStyle(
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: size.height * 0.004),
                          SizedBox(
                            width: size.width * 0.85,
                            child: ingredient.expirationDate != null
                                ? (() {
                                    final now = DateTime.now();
                                    final exp = ingredient.expirationDate!;
                                    final expDate =
                                        DateTime(exp.year, exp.month, exp.day);
                                    final today =
                                        DateTime(now.year, now.month, now.day);
                                    final daysLeft =
                                        expDate.difference(today).inDays;
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${exp.year}.${exp.month.toString().padLeft(2, '0')}.${exp.day.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: size.width * 0.038,
                                            color: daysLeft < 0
                                                ? Colors.red
                                                : daysLeft == 0
                                                    ? Colors.orange
                                                    : daysLeft <= 5
                                                        ? Colors.blue[700]
                                                        : Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (daysLeft < 0)
                                          Text(
                                            '${daysLeft.abs()}일 지남',
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: size.width * 0.038),
                                          )
                                        else if (daysLeft == 0)
                                          Text(
                                            '소비기한 오늘까지',
                                            style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: size.width * 0.038),
                                          )
                                        else if (daysLeft <= 5)
                                          Text(
                                            '$daysLeft일 남음',
                                            style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: size.width * 0.038),
                                          )
                                      ],
                                    );
                                  })()
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (!selectionMode) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.remove_circle_outline,
                            color: Colors.grey, size: size.width * 0.06),
                        onPressed: onDecrease,
                      ),
                      SizedBox(
                        child: Text(
                          ingredient.quantity.toString(),
                          style: TextStyle(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.add_circle_outline,
                            color: Colors.grey, size: size.width * 0.06),
                        onPressed: onIncrease,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: size.width * 0.01,
            left: size.width * 0.02,
            child: selectionMode
                ? Checkbox(
                    value: checked,
                    onChanged: (_) {
                      if (onCheckChanged != null) onCheckChanged!();
                    },
                  )
                : IconButton(
                    icon: Icon(
                      isInCart
                          ? Icons.shopping_cart
                          : Icons.shopping_cart_outlined,
                      color: isInCart ? Colors.green : Colors.grey,
                      size: size.width * 0.06,
                    ),
                    onPressed: () {
                      if (isInCart) {
                        Provider.of<ShoppingCartProvider>(context,
                                listen: false)
                            .removeItem(ingredient);
                      } else {
                        onCart();
                      }
                    },
                    splashRadius: size.width * 0.06,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: isInCart ? '장바구니에서 제거' : '장바구니에 추가',
                  ),
          ),
          Positioned(
            top: size.width * 0.01,
            right: size.width * 0.005,
            child: selectionMode
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.close,
                        color: Colors.grey, size: size.width * 0.06),
                    onPressed: onDelete,
                    splashRadius: size.width * 0.06,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: '재료 삭제',
                  ),
          ),
        ],
      ),
    );
  }
}

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTabIndex = 0;
  bool _isSelectionMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // FridgeProvider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<FridgeProvider>(context, listen: false).initialize();
      await Provider.of<FridgeProvider>(context, listen: false)
          .initializeFromFirestore();
      await Provider.of<FridgeProvider>(context, listen: false)
          .loadMyNickname();
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _toggleSelectionMode(List<Ingredient> ingredients) {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Ingredient> ingredients) {
    setState(() {
      if (_selectedIds.length == ingredients.length) {
        _selectedIds.clear();
      } else {
        _selectedIds = ingredients.map((i) => i.id).toSet();
      }
    });
  }

  void _deleteSelected(FridgeProvider fridgeProvider) {
    final idsToDelete = _selectedIds.toList();
    for (final id in idsToDelete) {
      fridgeProvider.removeIngredientFromCurrentFridge(id);
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('선택한 재료가 삭제되었습니다.')),
    );
  }

  // Helper method to build ingredient list view
  Widget _buildIngredientListView(
      List<Ingredient> ingredients,
      IngredientProvider provider,
      FridgeProvider fridgeProvider,
      String emptyMessage) {
    if (ingredients.isEmpty) {
      return Center(child: Text(emptyMessage));
    } else {
      return ListView.separated(
        padding: const EdgeInsets.only(top: 15, bottom: 15),
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          final ingredient = ingredients[index];
          final cartProvider = Provider.of<ShoppingCartProvider>(context);
          final isInCart =
              cartProvider.cartItems.any((item) => item.id == ingredient.id);
          return IngredientCard(
            ingredient: ingredient,
            onDelete: () =>
                fridgeProvider.removeIngredientFromCurrentFridge(ingredient.id),
            onIncrease: () =>
                fridgeProvider.increaseQuantityInCurrentFridge(ingredient.id),
            onDecrease: () =>
                fridgeProvider.decreaseQuantityInCurrentFridge(ingredient.id),
            onCart: () {
              final ingredientForCart = Ingredient(
                id: ingredient.id,
                name: ingredient.name,
                storageType: ingredient.storageType,
                quantity: 1.0,
                expirationDate: null,
              );
              Provider.of<ShoppingCartProvider>(context, listen: false)
                  .addItem(ingredientForCart);
              setState(() {});
            },
            isInCart: isInCart,
            selectionMode: _isSelectionMode,
            checked: _selectedIds.contains(ingredient.id),
            onCheckChanged: () => _toggleSelect(ingredient.id),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 16),
      );
    }
  }

  // Helper method to build fridge item in drawer
  Widget _buildFridgeItem(BuildContext context, String fridgeId, String name,
      String subtitle, String detail, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 11,
        ),
      ),
      onTap: () {
        final fridgeProvider =
            Provider.of<FridgeProvider>(context, listen: false);
        fridgeProvider.setCurrentFridge(fridgeId);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name로 이동했습니다.'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  // Helper method to get fridge icon based on type
  IconData _getFridgeIcon(String type) {
    switch (type) {
      case '공유용':
        return Icons.group;
      case '개인용':
      default:
        return Icons.person;
    }
  }

  // Helper method to get fridge color based on type
  Color _getFridgeColor(String type) {
    switch (type) {
      case '공유용':
        return Colors.orange[600]!;
      case '개인용':
      default:
        return Colors.blue[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientProvider = Provider.of<IngredientProvider>(context);
    final fridgeProvider = Provider.of<FridgeProvider>(context);
    if (!fridgeProvider.isUserReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final currentFridge = fridgeProvider.currentFridge;
    final currentIngredients = fridgeProvider.currentFridgeIngredients;

    // 유통기한 정렬 함수
    int compareIngredients(Ingredient a, Ingredient b) {
      if (a.expirationDate == null && b.expirationDate == null) {
        return 0; // 둘 다 유통기한 없으면 순서 유지
      }
      if (a.expirationDate == null) {
        return 1; // a만 유통기한 없으면 b가 앞으로
      }
      if (b.expirationDate == null) {
        return -1; // b만 유통기한 없으면 a가 앞으로
      }
      return a.expirationDate!.compareTo(b.expirationDate!); // 둘 다 있으면 날짜 비교
    }

    final refrigeratedIngredients = currentIngredients
        .where(
            (ingredient) => ingredient.storageType == StorageType.refrigerated)
        .toList()
      ..sort(compareIngredients);
    final frozenIngredients = currentIngredients
        .where((ingredient) => ingredient.storageType == StorageType.frozen)
        .toList()
      ..sort(compareIngredients);
    final roomTemperatureIngredients = currentIngredients
        .where((ingredient) =>
            ingredient.storageType == StorageType.roomTemperature)
        .toList()
      ..sort(compareIngredients);

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100], // 배경색을 더 밝은 회색으로
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Drawer 헤더
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.08, // 7% 만큼
                  bottom: MediaQuery.of(context).size.height * 0.025, // 2.5% 만큼
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          return const SizedBox(height: 80);
                        }
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: user.photoURL != null
                              ? ClipOval(
                                  child: Image.network(
                                    user.photoURL!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.blue[600],
                                ),
                        );
                      },
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.015),
                    Consumer<FridgeProvider>(
                      builder: (context, fridgeProvider, _) {
                        if (!fridgeProvider.isUserReady) {
                          return const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          );
                        }
                        final nickname =
                            fridgeProvider.getMyNickname() ?? '로그인을 해주세요';
                        return Column(
                          children: [
                            Text(
                              nickname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (user == null)
                              TextButton(
                                onPressed: () async {
                                  await GoogleAuthHelper.signInWithGoogle(
                                      context);
                                  if (!context.mounted) return;
                                  final fridgeProvider =
                                      Provider.of<FridgeProvider>(context,
                                          listen: false);
                                  await fridgeProvider.initialize();
                                  await fridgeProvider
                                      .initializeFromFirestore();
                                  setState(() {});
                                },
                                child: const Text(
                                  '로그인 하기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return const SizedBox.shrink();
                        return TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const MyPageScreen()),
                            );
                          },
                          child: const Text(
                            '내 정보 수정하기',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                decoration: TextDecoration.underline),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.005),
                  ],
                ),
              ),
              // 냉장고 목록
              Expanded(
                child: fridgeProvider.isUserReady
                    ? ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // 냉장고 목록 헤더
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.list,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '나의 냉장고',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 냉장고 아이템들
                          ...fridgeProvider.fridges.map((fridge) {
                            final ingredients = fridgeProvider
                                .getIngredientsForFridge(fridge.id);
                            String subtitle = fridge.type;
                            return _buildFridgeItem(
                              context,
                              fridge.id,
                              fridge.name,
                              subtitle,
                              '재료 ${ingredients.length}개',
                              _getFridgeIcon(fridge.type),
                              _getFridgeColor(fridge.type),
                            );
                          }).toList(),
                          const Divider(height: 32),
                          // 새 냉장고 추가 버튼
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              '새 냉장고 추가',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context); // 드로어 닫기
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddFridgeScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              // 하단 정보
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'G Fridge v1.0',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(currentFridge?.name ?? 'G Fridge'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: Icon(
                    _selectedIds.length ==
                                Provider.of<FridgeProvider>(context,
                                        listen: false)
                                    .currentFridgeIngredients
                                    .length &&
                            Provider.of<FridgeProvider>(context, listen: false)
                                .currentFridgeIngredients
                                .isNotEmpty
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  tooltip: '전체 선택',
                  onPressed: () {
                    final fridgeProvider =
                        Provider.of<FridgeProvider>(context, listen: false);
                    _selectAll(fridgeProvider.currentFridgeIngredients);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '선택 삭제',
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          final fridgeProvider = Provider.of<FridgeProvider>(
                              context,
                              listen: false);
                          _deleteSelected(fridgeProvider);
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: '취소',
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                    });
                  },
                ),
              ]
            : [
                // WishList button
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WishListScreen()),
                    );
                  },
                  tooltip: '위시리스트',
                ),
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'select') {
                      final fridgeProvider =
                          Provider.of<FridgeProvider>(context, listen: false);
                      _toggleSelectionMode(
                          fridgeProvider.currentFridgeIngredients);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'select',
                      child: Text(_isSelectionMode ? '선택 모드 해제' : '전체 선택 모드'),
                    ),
                  ],
                ),
              ],
        bottom: _selectedTabIndex == 0
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '냉장'),
                  Tab(text: '냉동'),
                  Tab(text: '실온'),
                ],
              )
            : null,
      ),
      body: _selectedTabIndex == 0
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildIngredientListView(refrigeratedIngredients,
                    ingredientProvider, fridgeProvider, '냉장 재료가 없습니다.'),
                _buildIngredientListView(frozenIngredients, ingredientProvider,
                    fridgeProvider, '냉동 재료가 없습니다.'),
                _buildIngredientListView(roomTemperatureIngredients,
                    ingredientProvider, fridgeProvider, '실온 재료가 없습니다.'),
              ],
            )
          : _selectedTabIndex == 1
              ? const ShoppingCartScreen()
              : const FridgeInfoScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: '냉장고',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: '장바구니',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: '냉장고 정보',
          ),
        ],
      ),
    );
  }
}
