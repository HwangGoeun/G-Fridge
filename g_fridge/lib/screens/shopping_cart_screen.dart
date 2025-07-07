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
  // bool _selectionMode = false;
  // final List<Set<String>> _tabSelectedIds = [
  //   <String>{},
  //   <String>{},
  //   <String>{}
  // ];

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
          title: widget.selectionMode
              ? Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: '뒤로가기',
                      onPressed: () {
                        if (widget.onToggleSelect != null) {
                          // 전체 선택 해제
                          for (int i = 0;
                              i < widget.selectedIdsList.length;
                              i++) {
                            for (final id
                                in widget.selectedIdsList[i].toList()) {
                              widget.onToggleSelect!(i, id);
                            }
                          }
                        }
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        widget.selectedIdsList[tabIdx].length ==
                                    _getTabItems(context)[tabIdx].length &&
                                _getTabItems(context)[tabIdx].isNotEmpty
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      tooltip: '전체 선택',
                      onPressed: () {
                        final items = _getTabItems(context)[tabIdx];
                        if (widget.onToggleSelect != null) {
                          if (widget.selectedIdsList[tabIdx].length ==
                              items.length) {
                            // 전체 해제
                            for (final id in items.map((i) => i.id)) {
                              if (widget.selectedIdsList[tabIdx].contains(id)) {
                                widget.onToggleSelect!(tabIdx, id);
                              }
                            }
                          } else {
                            // 전체 선택
                            for (final id in items.map((i) => i.id)) {
                              if (!widget.selectedIdsList[tabIdx]
                                  .contains(id)) {
                                widget.onToggleSelect!(tabIdx, id);
                              }
                            }
                          }
                        }
                      },
                    ),
                  ],
                )
              : const Text('장바구니', style: TextStyle(color: Colors.black)),
          actions: widget.selectionMode
              ? []
              : [
                  IconButton(
                    icon: const Icon(Icons.check_box_outlined),
                    tooltip: '전체 선택 모드',
                    onPressed: () {
                      if (widget.onToggleSelect != null) {
                        // selectionMode를 부모에서 관리해야 함
                        // 예: setState(() => selectionMode = true)
                      }
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
                                print('[체크박스] onChanged: ${ingredient.id}');
                                print(
                                    '[체크박스] 현재 선택된 id 리스트: ${widget.selectedIdsList[tabIdx]}');
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
                          if (!widget.selectionMode)
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
                          if (!widget.selectionMode)
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
