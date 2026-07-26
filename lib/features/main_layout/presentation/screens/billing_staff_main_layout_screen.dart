import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/features/billing/presentation/screens/invoice_scan_screen.dart';
import 'package:vishnu_enterprises/features/customers/presentation/screens/billing_customers_screen.dart';
import 'package:vishnu_enterprises/features/home/presentation/screens/billing_dashboard_screen.dart';
import 'package:vishnu_enterprises/features/main_layout/bloc/nav_cubit.dart';
import 'package:vishnu_enterprises/features/stock/presentation/screens/billing_stock_in_screen.dart';

class BillingStaffMainLayoutScreen extends StatelessWidget {
  const BillingStaffMainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BillingDashboardScreen(
        onStartBilling: () {
          context.read<NavCubit>().selectTab(2);
        },
      ),
      const BillingStockInScreen(),
      const InvoiceScanScreen(),
      const BillingCustomersScreen(),
    ];

    return BlocBuilder<NavCubit, int>(
      builder: (context, currentTab) {
        final safeIndex = currentTab >= pages.length ? 0 : currentTab;

        return PopScope(
          canPop: safeIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            context.read<NavCubit>().selectTab(0);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: List.generate(pages.length, (index) {
                final isActive = safeIndex == index;
                return IgnorePointer(
                  ignoring: !isActive,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutQuart,
                    opacity: isActive ? 1.0 : 0.0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutQuart,
                      scale: isActive ? 1.0 : 0.98,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutQuart,
                        offset: isActive ? Offset.zero : const Offset(0, 0.02),
                        child: TickerMode(
                          enabled: isActive,
                          child: pages[index],
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
                        color: Colors.black.withOpacity(0.06),
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
                          label: 'Dashboard',
                          isSelected: safeIndex == 0,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            HapticFeedback.selectionClick();
                            context.read<NavCubit>().selectTab(0);
                          },
                        ),
                        _NavItem(
                          icon: CupertinoIcons.cube_box_fill,
                          label: 'Stock In',
                          isSelected: safeIndex == 1,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            HapticFeedback.selectionClick();
                            context.read<NavCubit>().selectTab(1);
                          },
                        ),
                        _NavItem(
                          icon: CupertinoIcons.doc_text_fill,
                          label: 'Billing',
                          isSelected: safeIndex == 2,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            HapticFeedback.selectionClick();
                            context.read<NavCubit>().selectTab(2);
                          },
                        ),
                        _NavItem(
                          icon: CupertinoIcons.person_2_fill,
                          label: 'Customers',
                          isSelected: safeIndex == 3,
                          onTap: () {
                            HapticFeedback.lightImpact();
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
                  duration: 200.ms,
                  curve: Curves.easeOutBack,
                )
                .tint(color: AppColors.primary, end: 1.0, duration: 150.ms),
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
                  duration: 200.ms,
                  curve: Curves.easeOutBack,
                ),
          ],
        ),
      ),
    );
  }
}
