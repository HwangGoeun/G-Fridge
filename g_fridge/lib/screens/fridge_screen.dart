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

// IngredientCard 위젯 추가
class IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onDelete;
  final VoidCallback onCart;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isInCart;

  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.onDelete,
    required this.onCart,
    required this.onIncrease,
    required this.onDecrease,
    this.isInCart = false,
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
                                          '${exp.year}년 ${exp.month}월 ${exp.day}일',
                                          style: TextStyle(
                                            fontSize: size.width * 0.032,
                                            color: (expDate.isBefore(today) ||
                                                    expDate.isAtSameMomentAs(
                                                        today))
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (expDate.isBefore(today))
                                          Text(
                                            '${today.difference(expDate).inDays}일 지남',
                                            style: TextStyle(
                                              fontSize: size.width * 0.032,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        else if (expDate
                                            .isAtSameMomentAs(today))
                                          Text(
                                            '오늘까지',
                                            style: TextStyle(
                                              fontSize: size.width * 0.032,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        else if (daysLeft <= 5)
                                          Text(
                                            '$daysLeft일 남음',
                                            style: TextStyle(
                                              fontSize: size.width * 0.032,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    );
                                  })()
                                : Text(
                                    '소비기한을 입력하세요',
                                    style: TextStyle(
                                      fontSize: size.width * 0.032,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                      right: size.width * 0.01, bottom: size.width * 0.01),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
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
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: size.width * 0.01,
            left: size.width * 0.02,
            child: IconButton(
              icon: Icon(
                isInCart ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                color: isInCart ? Colors.green : Colors.grey,
                size: size.width * 0.06,
              ),
              onPressed: () {
                if (isInCart) {
                  Provider.of<ShoppingCartProvider>(context, listen: false)
                      .removeItem(ingredient);
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(
                  //     content: Text('${ingredient.name}이(가) 장바구니에서 제거되었습니다.'),
                  //     duration: const Duration(seconds: 2),
                  //   ),
                  // );
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
            child: IconButton(
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // FridgeProvider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FridgeProvider>(context, listen: false).initialize();
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          return Slidable(
            key: ValueKey(ingredient.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (context) {
                    final cartProvider = Provider.of<ShoppingCartProvider>(
                        context,
                        listen: false);
                    final isInCart = cartProvider.cartItems
                        .any((item) => item.id == ingredient.id);
                    if (isInCart) {
                      cartProvider.removeItem(ingredient);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${ingredient.name}이(가) 장바구니에서 제거되었습니다.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      final ingredientForCart = Ingredient(
                        id: ingredient.id,
                        name: ingredient.name,
                        storageType: ingredient.storageType,
                        quantity: 1.0,
                        expirationDate: null,
                      );
                      cartProvider.addItem(ingredientForCart);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${ingredient.name}이(가) 장바구니에 추가되었습니다.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  backgroundColor: isInCart ? Colors.grey[300]! : Colors.green,
                  foregroundColor: isInCart ? Colors.black : Colors.white,
                  icon: isInCart
                      ? Icons.remove_shopping_cart_rounded
                      : Icons.shopping_cart,
                  borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.045),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditIngredientScreen(
                        ingredient: ingredient,
                        ingredientIndex: provider.ingredients
                            .indexWhere((i) => i.id == ingredient.id)),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    IngredientCard(
                      ingredient: ingredient,
                      onDelete: () => fridgeProvider
                          .removeIngredientFromCurrentFridge(ingredient.id),
                      onIncrease: () => fridgeProvider
                          .increaseQuantityInCurrentFridge(ingredient.id),
                      onDecrease: () => fridgeProvider
                          .decreaseQuantityInCurrentFridge(ingredient.id),
                      onCart: () {
                        final ingredientForCart = Ingredient(
                          id: ingredient.id,
                          name: ingredient.name,
                          storageType: ingredient.storageType,
                          quantity: 1.0,
                          expirationDate: null,
                        );
                        Provider.of<ShoppingCartProvider>(context,
                                listen: false)
                            .addItem(ingredientForCart);
                        setState(() {});
                      },
                      isInCart: isInCart,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 16),
      );
    }
  }

  // Helper method to build fridge item in drawer
  Widget _buildFridgeItem(BuildContext context, String name, String subtitle,
      String detail, IconData icon, Color color) {
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
      onTap: () {
        // FridgeProvider를 사용하여 현재 냉장고 변경
        final fridgeProvider =
            Provider.of<FridgeProvider>(context, listen: false);
        final selectedFridge = fridgeProvider.fridges.firstWhere(
          (fridge) => fridge.name == name,
          orElse: () => fridgeProvider.fridges.first,
        );
        fridgeProvider.setCurrentFridge(selectedFridge.id);
        Navigator.pop(context); // 드로어 닫기
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
      case '가정용':
        return Icons.home;
      case '사무실용':
        return Icons.business;
      case '기숙사용':
        return Icons.apartment;
      default:
        return Icons.kitchen;
    }
  }

  // Helper method to get fridge color based on type
  Color _getFridgeColor(String type) {
    switch (type) {
      case '가정용':
        return Colors.blue[600]!;
      case '사무실용':
        return Colors.green[600]!;
      case '기숙사용':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientProvider = Provider.of<IngredientProvider>(context);
    final fridgeProvider = Provider.of<FridgeProvider>(context);
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
                    Container(
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
                      child: Icon(
                        Icons.kitchen,
                        size: 40,
                        color: Colors.blue[600],
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.015),
                    const Text(
                      'G Fridge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.005),
                    // Text(
                    //   '나의 냉장고 관리',
                    //   style: TextStyle(
                    //     color: Colors.blue[100],
                    //     fontSize: 14,
                    //   ),
                    // ),
                  ],
                ),
              ),
              // 냉장고 목록
              Expanded(
                child: ListView(
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
                      final ingredients =
                          fridgeProvider.getIngredientsForFridge(fridge.id);
                      return _buildFridgeItem(
                        context,
                        fridge.name,
                        '${fridge.type} • ${fridge.location}',
                        '재료 ${ingredients.length}개',
                        _getFridgeIcon(fridge.type),
                        _getFridgeColor(fridge.type),
                      );
                    }).toList(),
                    const Divider(height: 32),
                    // // 새 냉장고 추가 버튼
                    // ListTile(
                    //   leading: Container(
                    //     width: 40,
                    //     height: 40,
                    //     decoration: BoxDecoration(
                    //       color: Colors.grey[100],
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     child: Icon(
                    //       Icons.add,
                    //       color: Colors.grey[600],
                    //       size: 20,
                    //     ),
                    //   ),
                    //   title: const Text(
                    //     '새 냉장고 추가',
                    //     style: TextStyle(
                    //       fontWeight: FontWeight.w500,
                    //     ),
                    //   ),
                    //   onTap: () {
                    //     Navigator.pop(context); // 드로어 닫기
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(
                    //         content: Text('새 냉장고 추가 기능은 준비 중입니다.'),
                    //         duration: Duration(seconds: 2),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
              // 하단 정보
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Divider(),
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
        actions: [
          // Shopping cart button
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ShoppingCartScreen()),
              );
            },
            tooltip: '장바구니',
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
            icon: Icon(Icons.info_outline),
            label: '냉장고 정보',
          ),
        ],
      ),
    );
  }
}
