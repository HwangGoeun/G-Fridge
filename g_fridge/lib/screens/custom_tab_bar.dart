import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final TabController tabController;
  final List<String> tabTitles;
  final void Function()? onTabChanged;

  const CustomTabBar({
    Key? key,
    required this.tabController,
    required this.tabTitles,
    this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedIndex = tabController.index;
    final screenWidth = MediaQuery.of(context).size.width;
    const tabHeight = 40.0;
    final borderRadius = BorderRadius.circular(12);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.08,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabTitles.length, (i) {
          final isSelected = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                tabController.animateTo(i);
                if (onTabChanged != null) onTabChanged!();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: tabHeight,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.transparent,
                  borderRadius: i == 0
                      ? BorderRadius.only(
                          topLeft: borderRadius.topLeft,
                          bottomLeft: borderRadius.bottomLeft)
                      : i == tabTitles.length - 1
                          ? BorderRadius.only(
                              topRight: borderRadius.topRight,
                              bottomRight: borderRadius.bottomRight)
                          : BorderRadius.zero,
                ),
                child: Center(
                  child: Text(
                    tabTitles[i],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blue[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
