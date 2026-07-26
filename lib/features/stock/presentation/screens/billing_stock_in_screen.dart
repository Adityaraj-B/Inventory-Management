import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/theme/app_text_styles.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/core/widgets/app_card.dart';
import 'package:vishnu_enterprises/core/widgets/empty_state.dart';
import 'package:vishnu_enterprises/core/widgets/loading_indicator.dart';
import 'package:vishnu_enterprises/core/widgets/search_bar_widget.dart';
import 'package:vishnu_enterprises/data/models/stock_movement.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_bloc.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_event.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_state.dart';
import 'package:vishnu_enterprises/features/stock/presentation/widgets/add_stock_warehouse_modal.dart';
import 'package:vishnu_enterprises/features/stock/presentation/widgets/product_tile.dart';

class BillingStockInScreen extends StatefulWidget {
  const BillingStockInScreen({super.key});

  @override
  State<BillingStockInScreen> createState() => _BillingStockInScreenState();
}

class _BillingStockInScreenState extends State<BillingStockInScreen> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final warehouseId = authState is AuthAuthenticated
        ? authState.user.warehouseId
        : null;
    context.read<StockBloc>().add(StockLoadRequested(warehouseId: warehouseId));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final authState = context.read<AuthBloc>().state;
    final warehouseId = authState is AuthAuthenticated
        ? authState.user.warehouseId
        : null;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<StockBloc>().add(
        StockSearchChanged(query, warehouseId: warehouseId),
      );
    });
  }

  void _showHistoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(modalContext).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock_fill,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Stock Movement Log',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<StockBloc, StockState>(
                  builder: (context, state) {
                    if (state is StockLoading) {
                      return const LoadingIndicator(
                        message: 'Loading stock history...',
                      );
                    }

                    if (state is StockLoaded) {
                      if (state.history.isEmpty) {
                        return const EmptyState(
                          title: 'No movement records',
                          message: 'Stock movement entries will appear here.',
                          icon: CupertinoIcons.clock_fill,
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                        itemCount: state.history.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = state.history[index];
                          return _BillingStockMovementTile(movement: item)
                              .animate()
                              .fade(duration: 400.ms, delay: (index * 50).ms)
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutQuart,
                                delay: (index * 50).ms,
                              );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stock Directory'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.clock_fill, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showHistoryBottomSheet(context);
            },
            tooltip: 'Stock Movement History',
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.extended(
          heroTag: 'fab_add_billing_stock',
          onPressed: () {
            HapticFeedback.lightImpact();
            AddStockWarehouseModal.show(
              context,
              targetWarehouseId: user?.warehouseId,
            );
          },
          icon: const Icon(CupertinoIcons.add, size: 18),
          label: const Text('Add Stock in Warehouse'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBarWidget(
              hintText: 'Search stock in warehouse...',
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: BlocBuilder<StockBloc, StockState>(
              builder: (context, state) {
                if (state is StockLoading) {
                  return const LoadingIndicator(
                    message: 'Loading inventory products...',
                  );
                }

                if (state is StockError) {
                  return EmptyState(
                    title: 'Failed to load stock',
                    message: state.message,
                    icon: CupertinoIcons.exclamationmark_triangle,
                    action: ElevatedButton(
                      onPressed: () {
                        final whId = user?.warehouseId;
                        context.read<StockBloc>().add(
                          StockLoadRequested(warehouseId: whId),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  );
                }

                if (state is StockLoaded) {
                  if (state.products.isEmpty) {
                    return EmptyState(
                      title: state.searchQuery.isEmpty
                          ? 'No products in warehouse'
                          : 'No matching products',
                      message: state.searchQuery.isEmpty
                          ? 'No items registered for your warehouse yet.'
                          : 'Try searching with a different keyword or SKU.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                    itemCount: state.products.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return ProductTile(
                            product: product,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push(
                                RoutePaths.editStock,
                                extra: product,
                              );
                            },
                          )
                          .animate()
                          .fade(duration: 400.ms, delay: (index * 50).ms)
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOutQuart,
                            delay: (index * 50).ms,
                          );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingStockMovementTile extends StatelessWidget {
  final StockMovement movement;

  const _BillingStockMovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isAdd = movement.delta > 0;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAdd
                ? AppColors.successBackground
                : AppColors.errorBackground,
            child: Icon(
              isAdd
                  ? CupertinoIcons.arrow_down_left
                  : CupertinoIcons.arrow_up_right,
              color: isAdd ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.productName, style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(movement.reason, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(
                  Formatters.dateTime(movement.timestamp),
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            '${isAdd ? '+' : ''}${movement.delta}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isAdd ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
