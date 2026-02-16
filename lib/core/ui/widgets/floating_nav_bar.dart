import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.softYellow, // Dashboard
      AppColors.cyan,       // Speed Test
      AppColors.salmon,     // Analytics
      AppColors.periwinkle, // Settings
    ];

    final icons = [
      Icons.speed_rounded,
      Icons.shutter_speed_rounded,
      Icons.analytics_rounded,
      Icons.settings_rounded,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          // Account for 2px border on each side + 4px inner padding on each side
          const double borderWidth = 2.0;
          const double innerPadding = 4.0;
          final double availableWidth = totalWidth - (borderWidth * 2) - (innerPadding * 2);
          final double itemWidth = availableWidth / 4;
          
          // Indicator dimensions
          // We want the indicator to be slightly smaller than the item slot
          const indicatorPadding = 4.0;
          final indicatorWidth = itemWidth - (indicatorPadding * 2);
          
          final indicatorPosition = (itemWidth * currentIndex) + indicatorPadding;

          return Container(
            height: 60,
            width: totalWidth,
            padding: const EdgeInsets.symmetric(horizontal: innerPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Sliding Indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  left: indicatorPosition,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: indicatorWidth,
                    decoration: BoxDecoration(
                      color: colors[currentIndex],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colors[currentIndex].withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                // Icons
                Row(
                  children: List.generate(4, (index) {
                    return SizedBox(
                      width: itemWidth,
                      height: 60,
                      child: _NavItem(
                        icon: icons[index],
                        isSelected: currentIndex == index,
                        onTap: () => onTap(index),
                        selectedColor: AppColors.background,
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = AppColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              key: ValueKey(isSelected),
              color: isSelected ? selectedColor : AppColors.textMuted,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
