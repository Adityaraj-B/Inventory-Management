import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/features/customers/presentation/screens/admin_customers_screen.dart';
import 'package:vishnu_enterprises/features/home/presentation/screens/admin_home_screen.dart';
import 'package:vishnu_enterprises/features/main_layout/bloc/nav_cubit.dart';
import 'package:vishnu_enterprises/features/stock/presentation/screens/stock_in_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vishnu_enterprises/features/warehouse/presentation/screens/warehouse_list_screen.dart';

class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  final List<Widget> _pages = const [
    AdminHomeScreen(),
    StockInScreen(),
    AdminCustomersScreen(),
    WarehouseListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavCubit, int>(
      builder: (context, currentTab) {
        return PopScope(
          canPop: currentTab == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            context.read<NavCubit>().selectTab(0);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: List.generate(_pages.length, (index) {
                final isActive = currentTab == index;
                return IgnorePointer(
                  ignoring: !isActive,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.fastLinearToSlowEaseIn,
                    opacity: isActive ? 1.0 : 0.0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.fastLinearToSlowEaseIn,
                      scale: isActive ? 1.0 : 0.98,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.fastLinearToSlowEaseIn,
                        offset: isActive ? Offset.zero : const Offset(0, 0.02),
                        child: TickerMode(
                          enabled: isActive,
                          child: _pages[index],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            extendBody: true,
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavItem(
                          icon: CupertinoIcons.house_fill,
                          label: 'Home',
                          isSelected: currentTab == 0,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<NavCubit>().selectTab(0);
                          },
                        ),
                        _NavItem(
                          icon: CupertinoIcons.cube_box_fill,
                          label: 'Stock',
                          isSelected: currentTab == 1,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<NavCubit>().selectTab(1);
                          },
                        ),
                        _NavItem(
                          icon: CupertinoIcons.person_2_fill,
                          label: 'Customers',
                          isSelected: currentTab == 2,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<NavCubit>().selectTab(2);
                          },
                        ),
                        _NavItem(
                          icon: CupertinoIcons.building_2_fill,
                          label: 'Warehouses',
                          isSelected: currentTab == 3,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<NavCubit>().selectTab(3);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color)
                .animate(target: isSelected ? 1 : 0)
                .scaleXY(
                  begin: 1.0,
                  end: 1.15,
                  duration: 400.ms,
                  curve: Curves.fastLinearToSlowEaseIn,
                )
                .tint(color: AppColors.primary, end: 1.0, duration: 200.ms),
            const SizedBox(height: 3),
            Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: color,
                  ),
                )
                .animate(target: isSelected ? 1 : 0)
                .scaleXY(
                  begin: 0.95,
                  end: 1.0,
                  duration: 400.ms,
                  curve: Curves.fastLinearToSlowEaseIn,
                ),
          ],
        ),
      ),
    );
  }
}
