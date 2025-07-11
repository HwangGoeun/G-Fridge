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
import 'package:reorderables/reorderables.dart';
import 'custom_tab_bar.dart';
import '../models/fridge.dart';

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
    int? daysLeft;
    if (ingredient.expirationDate != null) {
      final now = DateTime.now();
      final exp = ingredient.expirationDate!;
      final expDate = DateTime(exp.year, exp.month, exp.day);
      final today = DateTime(now.year, now.month, now.day);
      daysLeft = expDate.difference(today).inDays;
    }
    return SizedBox(
      child: Stack(
        children: [
          // 카드 배경/테두리
          Container(
            decoration: BoxDecoration(
              color: daysLeft != null && daysLeft < 0
                  ? const Color(0x00ffcccc).withOpacity(0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: daysLeft != null && daysLeft < 0
                  ? Border.all(color: Colors.red.withOpacity(0.1))
                  : Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: size.width * 0.0085,
                  blurRadius: size.width * 0.017,
                  offset: Offset(0, size.height * 0.0017),
                ),
              ],
            ),
          ),
          // 카드 내용
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: size.height * 0.01, horizontal: size.width * 0.03),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: size.width * 0.3,
                      child: Text(
                        ingredient.ingredientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!selectionMode)
                      Text(
                        '${ingredient.quantity}개',
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ingredient.expirationDate != null
                          ? '${ingredient.expirationDate!.year}.${ingredient.expirationDate!.month.toString().padLeft(2, '0')}.${ingredient.expirationDate!.day.toString().padLeft(2, '0')}'
                          : '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      daysLeft == null
                          ? ''
                          : daysLeft < 0
                              ? '${daysLeft.abs()}일 지남'
                              : daysLeft == 0
                                  ? '오늘까지'
                                  : '$daysLeft일 남음',
                      style: TextStyle(
                        color: daysLeft == null
                            ? Colors.grey
                            : daysLeft < 0 || daysLeft <= 7
                                ? Colors.red
                                : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 전체 선택 모드일 때만 체크박스
          if (selectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Transform.scale(
                scale: 0.7,
                child: Checkbox(
                  value: checked,
                  onChanged: (_) {
                    if (onCheckChanged != null) onCheckChanged!();
                  },
                  visualDensity: VisualDensity.compact,
                ),
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
    with TickerProviderStateMixin {
  late TabController _tabController;
  TabController? _cartTabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTabIndex = 0;
  // 탭별 selectionMode/selectedIds 분리
  final List<Set<String>> _tabSelectedIds = [
    <String>{},
    <String>{},
    <String>{}
  ];
  final List<bool> _tabSelectionMode = [false, false, false];
  // 냉장고 순서 변경 모드
  bool _isReorderMode = false;
  // 전체 선택 모드
  bool _selectionMode = false;
  // 장바구니 탭 서브탭별 선택 상태
  List<Set<String>> _cartTabSelectedIds = [<String>{}, <String>{}, <String>{}];
  List<Fridge> _prevFridgeList = [];
  final bool _kickedDialogShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cartTabController = TabController(length: 3, vsync: this);
    _cartTabController!.addListener(() {
      if (_selectedTabIndex == 1 && _tabSelectionMode[1]) {
        setState(() {}); // 장바구니 탭의 서브탭 이동 시 앱바 갱신
      }
    });
    // FridgeProvider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<FridgeProvider>(context, listen: false).initialize();
      await Provider.of<FridgeProvider>(context, listen: false)
          .initializeFromFirestore();
      await Provider.of<FridgeProvider>(context, listen: false)
          .loadMyNickname();
    });
    _tabController.addListener(() {
      if (mounted && _tabController.indexIsChanging == false) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fridgeProvider = Provider.of<FridgeProvider>(context);
    final currentFridgeList = fridgeProvider.fridges;
    final currentFridgeIds = currentFridgeList.map((f) => f.id).toSet();
    // 강퇴 감지: 이전엔 있었는데 지금은 없는 공유 냉장고
    for (final prev in _prevFridgeList) {
      final wasShared = prev.sharedWith.isNotEmpty;
      if (wasShared &&
          !currentFridgeIds.contains(prev.id) &&
          !_kickedDialogShown) {
        // 강퇴 알림 다이얼로그 제거: showDialog 호출 부분 삭제
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (!_kickedDialogShown && mounted) {
        //     _kickedDialogShown = true;
        //     showDialog(
        //       context: context,
        //       builder: (_) => AlertDialog(
        //         title: const Text('강퇴 알림'),
        //         content: const Text('공유 냉장고에서 강퇴되었습니다.'),
        //         actions: [
        //           TextButton(
        //             onPressed: () {
        //               Navigator.of(context).pop();
        //               setState(() {
        //                 _kickedDialogShown = false;
        //               });
        //             },
        //             child: const Text('확인'),
        //           ),
        //         ],
        //       ),
        //     );
        //   }
        // });
      }
    }
    _prevFridgeList = List<Fridge>.from(currentFridgeList);
  }

  void _onBottomNavTapped(int index) async {
    setState(() {
      _selectedTabIndex = index;
    });
    if (index == 0 || index == 2) {
      // 냉장고 탭 또는 냉장고 정보 탭을 누를 때마다 동기화
      await Provider.of<FridgeProvider>(context, listen: false)
          .initializeFromFirestore();
    }
  }

  // Helper method to build ingredient list view
  Widget _buildIngredientListView(
      List<Ingredient> ingredients,
      IngredientProvider provider,
      FridgeProvider fridgeProvider,
      String emptyMessage,
      {bool selectionMode = false,
      Set<String> selectedIds = const {},
      void Function(String id)? onToggleSelect}) {
    if (ingredients.isEmpty) {
      return Center(child: Text(emptyMessage));
    } else {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 한 줄에 2개
          mainAxisSpacing: 12, // 세로 간격
          crossAxisSpacing: 12, // 가로 간격
          childAspectRatio: 2.6, // 카드 비율(가로/세로)
        ),
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          final ingredient = ingredients[index];
          final cartProvider = Provider.of<ShoppingCartProvider>(context);
          final isInCart =
              cartProvider.cartItems.any((item) => item.id == ingredient.id);
          return GestureDetector(
            onTap: selectionMode
                ? null
                : () async {
                    await showDialog(
                      context: context,
                      builder: (context) => _EditFridgeIngredientDialog(
                        ingredient: ingredient,
                      ),
                    );
                  },
            child: IngredientCard(
              ingredient: ingredient,
              onDelete: () => fridgeProvider
                  .removeIngredientFromCurrentFridge(ingredient.id),
              onIncrease: () =>
                  fridgeProvider.increaseQuantityInCurrentFridge(ingredient.id),
              onDecrease: () =>
                  fridgeProvider.decreaseQuantityInCurrentFridge(ingredient.id),
              onCart: () {
                final ingredientForCart = Ingredient(
                  id: const Uuid().v4(),
                  ingredientName: ingredient.ingredientName,
                  storageType: ingredient.storageType,
                  quantity: 1.0,
                  expirationDate: null,
                );
                Provider.of<ShoppingCartProvider>(context, listen: false)
                    .addItem(ingredientForCart);
              },
              isInCart: isInCart,
              selectionMode: selectionMode,
              checked: selectedIds.contains(ingredient.id),
              onCheckChanged: onToggleSelect == null
                  ? null
                  : () => onToggleSelect(ingredient.id),
            ),
          );
        },
      );
    }
  }

  // Helper method to build fridge item in drawer
  Widget _buildFridgeItem(BuildContext context, String fridgeId, String name,
      String subtitle, String detail, IconData icon, Color color,
      {Key? key}) {
    return ListTile(
      key: key,
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
    final tabIdx = _cartTabController?.index ?? 0;
    final ingredientProvider = Provider.of<IngredientProvider>(context);
    final fridgeProvider = Provider.of<FridgeProvider>(context);

    // 데이터 준비 전에는 로딩 표시
    if (!fridgeProvider.isUserReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final currentFridge = fridgeProvider.currentFridge;
    // 냉장고가 바뀔 때마다 실시간 재료 및 장바구니 구독
    if (currentFridge != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ingredientProvider.setFridgeId(currentFridge.id);
        Provider.of<ShoppingCartProvider>(context, listen: false)
            .setFridgeId(currentFridge.id);
      });
    }
    final currentIngredients = ingredientProvider.ingredients;
    print(
        '[FridgeScreen] ingredientProvider.ingredients.length = ${currentIngredients.length}');

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

    print(
        '[FridgeScreen] refrigeratedIngredients.length = ${refrigeratedIngredients.length}');
    print(
        '[FridgeScreen] frozenIngredients.length = ${frozenIngredients.length}');
    print(
        '[FridgeScreen] roomTemperatureIngredients.length = ${roomTemperatureIngredients.length}');

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100], // 배경색을 더 밝은 회색으로
      drawer: Drawer(
        child: Consumer<FridgeProvider>(
          builder: (context, fridgeProvider, _) => Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Drawer 헤더
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.08, // 7% 만큼
                    bottom:
                        MediaQuery.of(context).size.height * 0.025, // 2.5% 만큼
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
                      // 기존 Consumer<FridgeProvider> 부분은 제거 (중복 방지)
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          );
                        },
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005),
                    ],
                  ),
                ),
                // 나의 냉장고 헤더 (버튼)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isReorderMode = !_isReorderMode;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_vert,
                          color:
                              _isReorderMode ? Colors.blue : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '냉장고 순서 변경하기',
                          style: TextStyle(
                            color:
                                _isReorderMode ? Colors.blue : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isReorderMode ? Icons.check : Icons.edit,
                          color:
                              _isReorderMode ? Colors.blue : Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                // 냉장고 리스트 (드래그/정렬 없음)
                ...fridgeProvider.fridges.asMap().entries.map((entry) {
                  final index = entry.key;
                  final fridge = entry.value;
                  final ingredients =
                      fridgeProvider.getIngredientsForFridge(fridge.id);
                  String displayType = fridge.type;
                  if (fridge.sharedWith.isNotEmpty) {
                    displayType = '공유용';
                  }
                  String subtitle = displayType;
                  return Row(
                    key: ValueKey('fridge-${fridge.id}'),
                    children: [
                      Expanded(
                        child: _buildFridgeItem(
                          context,
                          fridge.id,
                          fridge.name,
                          subtitle,
                          '재료 ${ingredients.length}개',
                          _getFridgeIcon(displayType),
                          _getFridgeColor(displayType),
                          key: ValueKey('fridge-${fridge.id}'),
                        ),
                      ),
                      if (_isReorderMode) ...[
                        // 위로 이동 버튼
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 20),
                          tooltip: '위로 이동',
                          onPressed: index > 0
                              ? () async {
                                  await Provider.of<FridgeProvider>(context,
                                          listen: false)
                                      .moveFridgeOrder(index, index - 1);
                                }
                              : null,
                        ),
                        // 아래로 이동 버튼
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 20),
                          tooltip: '아래로 이동',
                          onPressed: index < fridgeProvider.fridges.length - 1
                              ? () async {
                                  await Provider.of<FridgeProvider>(context,
                                          listen: false)
                                      .moveFridgeOrder(index, index + 1);
                                }
                              : null,
                        ),
                      ],
                    ],
                  );
                }).toList(),
                // Divider (드래그 불가)
                const Divider(key: ValueKey('fridge-divider'), height: 32),
                // 새 냉장고 추가 버튼 (드래그 불가)
                ListTile(
                  key: const ValueKey('fridge-add'),
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
            ),
          ),
        ),
      ),
      onDrawerChanged: (isOpened) async {
        if (isOpened) {
          await Provider.of<FridgeProvider>(context, listen: false)
              .initializeFromFirestore();
        }
      },
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: _selectedTabIndex == 0 && _selectionMode
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '뒤로가기',
                    onPressed: () {
                      setState(() {
                        _selectionMode = false;
                        for (int i = 0; i < 3; i++) {
                          _tabSelectedIds[i].clear();
                        }
                      });
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _tabSelectedIds[_tabController.index].length ==
                                  getIngredientsByTab(_tabController.index,
                                          currentIngredients)
                                      .length &&
                              getIngredientsByTab(
                                      _tabController.index, currentIngredients)
                                  .isNotEmpty
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    tooltip: '전체 선택',
                    onPressed: () {
                      final ingredients = getIngredientsByTab(
                          _tabController.index, currentIngredients);
                      setState(() {
                        if (_tabSelectedIds[_tabController.index].length ==
                            ingredients.length) {
                          _tabSelectedIds[_tabController.index].clear();
                        } else {
                          _tabSelectedIds[_tabController.index] =
                              ingredients.map((i) => i.id).toSet();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: '선택한 재료 장바구니에 추가',
                    onPressed: _tabSelectedIds.any((set) => set.isNotEmpty)
                        ? () {
                            final fridgeProvider = Provider.of<FridgeProvider>(
                                context,
                                listen: false);
                            final cartProvider =
                                Provider.of<ShoppingCartProvider>(context,
                                    listen: false);
                            final allSelectedIds =
                                _tabSelectedIds.expand((set) => set).toSet();
                            final ingredients = currentIngredients
                                .where((i) => allSelectedIds.contains(i.id))
                                .toList();
                            for (final ingredient in ingredients) {
                              cartProvider.addItem(
                                Ingredient(
                                  id: const Uuid().v4(),
                                  ingredientName: ingredient.ingredientName,
                                  storageType: ingredient.storageType,
                                  quantity: 1.0,
                                  expirationDate: null,
                                ),
                              );
                            }
                            setState(() {
                              for (int i = 0; i < 3; i++) {
                                _tabSelectedIds[i].clear();
                              }
                              _selectionMode = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('선택한 재료가 장바구니에 추가되었습니다!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '선택 삭제',
                    onPressed: _tabSelectedIds.any((set) => set.isNotEmpty)
                        ? () {
                            final fridgeProvider = Provider.of<FridgeProvider>(
                                context,
                                listen: false);
                            final allSelectedIds =
                                _tabSelectedIds.expand((set) => set).toSet();
                            for (final id in allSelectedIds) {
                              fridgeProvider
                                  .removeIngredientFromCurrentFridge(id);
                            }
                            setState(() {
                              for (int i = 0; i < 3; i++) {
                                _tabSelectedIds[i].clear();
                              }
                              _selectionMode = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('선택한 재료가 삭제되었습니다.')),
                            );
                          }
                        : null,
                  ),
                ],
              )
            : _selectedTabIndex == 1 && _tabSelectionMode[1]
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: '뒤로가기',
                        onPressed: () {
                          setState(() {
                            _tabSelectionMode[1] = false;
                            _cartTabSelectedIds[1].clear();
                          });
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          () {
                            final cartProvider =
                                Provider.of<ShoppingCartProvider>(context,
                                    listen: false);
                            List<Ingredient> currentTabItems;
                            // Use the same tab index as ShoppingCartScreen
                            final tabIdx = _cartTabController?.index ?? 0;
                            if (tabIdx == 0) {
                              currentTabItems = cartProvider.refrigeratedItems;
                            } else if (tabIdx == 1) {
                              currentTabItems = cartProvider.frozenItems;
                            } else {
                              currentTabItems =
                                  cartProvider.roomTemperatureItems;
                            }
                            return _cartTabSelectedIds[tabIdx].length ==
                                        currentTabItems.length &&
                                    currentTabItems.isNotEmpty
                                ? Icons.check_box
                                : Icons.check_box_outline_blank;
                          }(),
                        ),
                        tooltip: '전체 선택',
                        onPressed: () {
                          final cartProvider =
                              Provider.of<ShoppingCartProvider>(context,
                                  listen: false);
                          List<Ingredient> currentTabItems;
                          final tabIdx = _cartTabController?.index ?? 0;
                          if (tabIdx == 0) {
                            currentTabItems = cartProvider.refrigeratedItems;
                          } else if (tabIdx == 1) {
                            currentTabItems = cartProvider.frozenItems;
                          } else {
                            currentTabItems = cartProvider.roomTemperatureItems;
                          }
                          setState(() {
                            if (_cartTabSelectedIds[tabIdx].length ==
                                currentTabItems.length) {
                              _cartTabSelectedIds[tabIdx].clear();
                            } else {
                              _cartTabSelectedIds[tabIdx].clear();
                              _cartTabSelectedIds[tabIdx]
                                  .addAll(currentTabItems.map((i) => i.id));
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.kitchen_outlined),
                        tooltip: '선택한 재료 냉장고에 추가',
                        onPressed: _cartTabSelectedIds
                                .any((set) => set.isNotEmpty)
                            ? () async {
                                final fridgeProvider =
                                    Provider.of<FridgeProvider>(context,
                                        listen: false);
                                final cartProvider =
                                    Provider.of<ShoppingCartProvider>(context,
                                        listen: false);
                                final allSelectedIds = _cartTabSelectedIds
                                    .expand((set) => set)
                                    .toSet();
                                final selectedItems = cartProvider.cartItems
                                    .where((i) => allSelectedIds.contains(i.id))
                                    .toList();
                                for (final ingredient in selectedItems) {
                                  final newIngredient = ingredient.copyWith(
                                    id: DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString(),
                                    expirationDate: null,
                                  );
                                  await fridgeProvider
                                      .addIngredientToCurrentFridge(
                                          newIngredient);
                                  await cartProvider.removeItem(ingredient.id);
                                }
                                setState(() {
                                  for (int i = 0; i < 3; i++) {
                                    _cartTabSelectedIds[i].clear();
                                  }
                                  _tabSelectionMode[1] = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('선택한 재료가 냉장고에 추가되었습니다!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '선택 삭제',
                        onPressed: _cartTabSelectedIds
                                .any((set) => set.isNotEmpty)
                            ? () {
                                final cartProvider =
                                    Provider.of<ShoppingCartProvider>(context,
                                        listen: false);
                                final tabIdx = _cartTabController?.index ?? 0;
                                final idsToDelete =
                                    _cartTabSelectedIds[tabIdx].toList();
                                print('[앱바 선택 삭제] 삭제할 id 리스트: $idsToDelete');
                                for (final id in idsToDelete) {
                                  print('[앱바 선택 삭제] removeItem 호출: $id');
                                  cartProvider.removeItem(id);
                                }
                                setState(() {
                                  for (int i = 0; i < 3; i++) {
                                    _cartTabSelectedIds[i].clear();
                                  }
                                  _tabSelectionMode[1] = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('선택한 장바구니 재료가 삭제되었습니다.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ],
                  )
                : Text(currentFridge?.name ?? 'G Fridge'),
        actions: (_selectedTabIndex == 0 && _selectionMode) ||
                (_selectedTabIndex == 1 && _tabSelectionMode[1])
            ? []
            : [
                if (_selectedTabIndex == 0 || _selectedTabIndex == 1)
                  IconButton(
                    icon: const Icon(Icons.check_box_outlined),
                    tooltip: '전체 선택 모드',
                    onPressed: () {
                      setState(() {
                        if (_selectedTabIndex == 0) {
                          _selectionMode = true;
                        } else if (_selectedTabIndex == 1) {
                          _tabSelectionMode[1] = true;
                        }
                      });
                    },
                  ),
                if (_selectedTabIndex == 0)
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
                if (_selectedTabIndex == 0 || _selectedTabIndex == 1)
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
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: CustomTabBar(
                  tabController: _tabController,
                  tabTitles: const ['냉장', '냉동', '실온'],
                ),
              )
            : null,
      ),
      body: _selectedTabIndex == 0
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildIngredientListView(
                  refrigeratedIngredients,
                  ingredientProvider,
                  fridgeProvider,
                  '냉장 재료가 없습니다.',
                  selectionMode: _selectionMode,
                  selectedIds: _tabSelectedIds[0],
                  onToggleSelect: (id) {
                    setState(() {
                      if (_tabSelectedIds[0].contains(id)) {
                        _tabSelectedIds[0].remove(id);
                      } else {
                        _tabSelectedIds[0].add(id);
                      }
                    });
                  },
                ),
                _buildIngredientListView(
                  frozenIngredients,
                  ingredientProvider,
                  fridgeProvider,
                  '냉동 재료가 없습니다.',
                  selectionMode: _selectionMode,
                  selectedIds: _tabSelectedIds[1],
                  onToggleSelect: (id) {
                    setState(() {
                      if (_tabSelectedIds[1].contains(id)) {
                        _tabSelectedIds[1].remove(id);
                      } else {
                        _tabSelectedIds[1].add(id);
                      }
                    });
                  },
                ),
                _buildIngredientListView(
                  roomTemperatureIngredients,
                  ingredientProvider,
                  fridgeProvider,
                  '실온 재료가 없습니다.',
                  selectionMode: _selectionMode,
                  selectedIds: _tabSelectedIds[2],
                  onToggleSelect: (id) {
                    setState(() {
                      if (_tabSelectedIds[2].contains(id)) {
                        _tabSelectedIds[2].remove(id);
                      } else {
                        _tabSelectedIds[2].add(id);
                      }
                    });
                  },
                ),
              ],
            )
          : _selectedTabIndex == 1
              ? ShoppingCartScreen(
                  key: ValueKey(_cartTabSelectedIds.hashCode.toString() +
                      _tabSelectionMode[1].toString()),
                  tabController: _cartTabController,
                  selectionMode: _tabSelectionMode[1],
                  selectedIdsList: _cartTabSelectedIds,
                  onToggleSelect: (tabIdx, id) {
                    setState(() {
                      final newSet =
                          Set<String>.from(_cartTabSelectedIds[tabIdx]);
                      if (newSet.contains(id)) {
                        newSet.remove(id);
                      } else {
                        newSet.add(id);
                      }
                      // 완전히 새 List로 할당
                      _cartTabSelectedIds = List<Set<String>>.generate(
                        3,
                        (i) => i == tabIdx
                            ? newSet
                            : Set<String>.from(_cartTabSelectedIds[i]),
                      );
                      print(
                          '[FridgeScreen] 체크박스 클릭 후 _cartTabSelectedIds[$tabIdx]: ${_cartTabSelectedIds[tabIdx]}');
                    });
                  },
                )
              : const FridgeInfoScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        selectedIconTheme: const IconThemeData(color: Colors.blue, size: 28),
        unselectedIconTheme:
            const IconThemeData(color: Colors.black54, size: 24),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: '냉장고',
            backgroundColor: Color(0xFFE3F2FD), // 하늘색
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: '장바구니',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: '냉장고 정보',
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

// 탭별 재료 리스트 반환 함수
List<Ingredient> getIngredientsByTab(
    int tabIndex, List<Ingredient> ingredients) {
  if (tabIndex == 0) {
    return ingredients
        .where((i) => i.storageType == StorageType.refrigerated)
        .toList();
  }
  if (tabIndex == 1) {
    return ingredients
        .where((i) => i.storageType == StorageType.frozen)
        .toList();
  }
  return ingredients
      .where((i) => i.storageType == StorageType.roomTemperature)
      .toList();
}

class _EditFridgeIngredientDialog extends StatefulWidget {
  final Ingredient ingredient;
  const _EditFridgeIngredientDialog({Key? key, required this.ingredient})
      : super(key: key);

  @override
  State<_EditFridgeIngredientDialog> createState() =>
      _EditFridgeIngredientDialogState();
}

class _EditFridgeIngredientDialogState
    extends State<_EditFridgeIngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  double _quantity = 1.0;
  StorageType _selectedStorageType = StorageType.refrigerated;
  DateTime? _selectedExpirationDate;

  final Map<StorageType, String> _storageTypeLabels = {
    StorageType.refrigerated: '냉장',
    StorageType.frozen: '냉동',
    StorageType.roomTemperature: '실온',
  };

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.ingredient.ingredientName);
    _quantity = widget.ingredient.quantity;
    _selectedStorageType = widget.ingredient.storageType;
    _selectedExpirationDate = widget.ingredient.expirationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateIngredient() async {
    if (_formKey.currentState!.validate()) {
      final updatedIngredient = widget.ingredient.copyWith(
        ingredientName: _nameController.text,
        quantity: _quantity,
        storageType: _selectedStorageType,
        expirationDate: _selectedExpirationDate,
      );
      await Provider.of<FridgeProvider>(context, listen: false)
          .updateIngredientInCurrentFridge(updatedIngredient);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('재료가 수정되었습니다!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('재료 수정',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                // 이름
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '재료 이름',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '재료 이름을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // 수량
                Row(
                  children: [
                    Icon(Icons.scale_outlined, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text('수량',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          if (_quantity > 0.5) _quantity -= 0.5;
                        });
                      },
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(_quantity.toString(),
                          style: const TextStyle(fontSize: 16)),
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
                const SizedBox(height: 24),
                // 보관 방식
                Row(
                  children: [
                    Icon(Icons.storage_outlined, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text('보관 방식',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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
                            foregroundColor:
                                isSelected ? Colors.white : Colors.grey[700],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                const SizedBox(height: 24),
                // 유통기한
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text('유통기한',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
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
                const SizedBox(height: 24),
                SizedBox(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
