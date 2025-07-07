import 'package:flutter/material.dart';
import 'package:g_fridge/screens/add_ingredient_screen.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_cart_provider.dart';
import '../providers/ingredient_provider.dart'; // Import IngredientProvider to add to fridge
import '../providers/fridge_provider.dart'; // Import FridgeProvider
import 'package:uuid/uuid.dart';
import '../models/ingredient.dart';

class ShoppingCartScreen extends StatefulWidget {
  final bool selectionMode;
  final List<Set<String>> selectedIdsList;
  final void Function(int tabIdx, String id)? onToggleSelect;
  final TabController? tabController;
  const ShoppingCartScreen({
    super.key,
    this.selectionMode = false,
    required this.selectedIdsList,
    this.onToggleSelect,
    this.tabController,
  });

  @override
  _ShoppingCartScreenState createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _selectionMode = false;
  final List<Set<String>> _tabSelectedIds = [
    <String>{},
    <String>{},
    <String>{}
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        widget.tabController ?? TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final tabIdx = _tabController?.index ?? 0;
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: _selectionMode
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
                        _tabSelectedIds[tabIdx].length ==
                                    _getTabItems(context)[tabIdx].length &&
                                _getTabItems(context)[tabIdx].isNotEmpty
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      tooltip: '전체 선택',
                      onPressed: () {
                        final items = _getTabItems(context)[tabIdx];
                        setState(() {
                          if (_tabSelectedIds[tabIdx].length == items.length) {
                            _tabSelectedIds[tabIdx].clear();
                          } else {
                            _tabSelectedIds[tabIdx] =
                                items.map((i) => i.id).toSet();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.kitchen_outlined),
                      tooltip: '선택한 재료 냉장고에 추가',
                      onPressed: _tabSelectedIds[tabIdx].isEmpty
                          ? null
                          : () {
                              final fridgeProvider =
                                  Provider.of<FridgeProvider>(context,
                                      listen: false);
                              final cartProvider =
                                  Provider.of<ShoppingCartProvider>(context,
                                      listen: false);
                              final items = _getTabItems(context)[tabIdx]
                                  .where((i) =>
                                      _tabSelectedIds[tabIdx].contains(i.id))
                                  .toList();
                              for (final ingredient in items) {
                                final newIngredient = ingredient.copyWith(
                                  id: const Uuid().v4(),
                                  expirationDate: null,
                                );
                                fridgeProvider.addIngredientToCurrentFridge(
                                    newIngredient);
                                cartProvider.removeItem(ingredient.id);
                              }
                              setState(() {
                                _tabSelectedIds[tabIdx].clear();
                                _selectionMode = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('선택한 재료가 냉장고에 추가되었습니다!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '선택 삭제',
                      onPressed: _tabSelectedIds[tabIdx].isEmpty
                          ? null
                          : () {
                              final cartProvider =
                                  Provider.of<ShoppingCartProvider>(context,
                                      listen: false);
                              final idsToDelete =
                                  _tabSelectedIds[tabIdx].toList();
                              for (final id in idsToDelete) {
                                cartProvider.removeItem(id);
                              }
                              setState(() {
                                _tabSelectedIds[tabIdx].clear();
                                _selectionMode = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('선택한 재료가 삭제되었습니다.')),
                              );
                            },
                    ),
                  ],
                )
              : const Text('장바구니', style: TextStyle(color: Colors.black)),
          actions: _selectionMode
              ? []
              : [
                  IconButton(
                    icon: const Icon(Icons.check_box_outlined),
                    tooltip: '전체 선택 모드',
                    onPressed: () {
                      setState(() {
                        _selectionMode = true;
                      });
                    },
                  ),
                ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: '냉장'),
              Tab(text: '냉동'),
              Tab(text: '실온'),
            ],
          ),
        ),
      ),
      body: Consumer<ShoppingCartProvider>(
        builder: (context, cartProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: List.generate(3, (tabIdx) {
              final items = _getTabItems(context)[tabIdx];
              if (items.isEmpty) {
                return const Center(
                  child: Text('장바구니가 비어있습니다.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 5.0),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final ingredient = items[index];
                  return Card(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // 삭제 or 체크박스
                          if (widget.selectionMode)
                            Checkbox(
                              value: widget.selectedIdsList[tabIdx]
                                  .contains(ingredient.id),
                              onChanged: (_) {
                                if (widget.onToggleSelect != null) {
                                  widget.onToggleSelect!(tabIdx, ingredient.id);
                                }
                              },
                              visualDensity: VisualDensity.compact,
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                Provider.of<ShoppingCartProvider>(context,
                                        listen: false)
                                    .removeItem(ingredient.id);
                              },
                            ),
                          // 이름
                          Expanded(
                            child: Text(
                              ingredient.ingredientName,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          // 수량 조절
                          if (!_selectionMode)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20),
                                  onPressed: () {
                                    Provider.of<ShoppingCartProvider>(context,
                                            listen: false)
                                        .decreaseQuantity(ingredient.id);
                                  },
                                ),
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    ingredient.quantity.toString(),
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 20),
                                  onPressed: () {
                                    Provider.of<ShoppingCartProvider>(context,
                                            listen: false)
                                        .increaseQuantity(ingredient.id);
                                  },
                                ),
                              ],
                            ),
                          // 냉장고 추가 버튼 (선택 모드 아닐 때만)
                          if (!_selectionMode)
                            IconButton(
                              icon: const Icon(Icons.kitchen_outlined),
                              onPressed: () {
                                final fridgeProvider =
                                    Provider.of<FridgeProvider>(context,
                                        listen: false);
                                final newIngredient = ingredient.copyWith(
                                    id: const Uuid().v4(),
                                    expirationDate: null);
                                fridgeProvider.addIngredientToCurrentFridge(
                                    newIngredient);
                                Provider.of<ShoppingCartProvider>(context,
                                        listen: false)
                                    .removeItem(ingredient.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${ingredient.ingredientName}이 냉장고에 추가되었습니다.'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }

  List<List<Ingredient>> _getTabItems(BuildContext context) {
    final cartProvider =
        Provider.of<ShoppingCartProvider>(context, listen: false);
    return [
      cartProvider.refrigeratedItems,
      cartProvider.frozenItems,
      cartProvider.roomTemperatureItems,
    ];
  }
}
