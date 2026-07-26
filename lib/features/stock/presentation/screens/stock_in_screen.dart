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
import 'package:vishnu_enterprises/features/stock/bloc/stock_bloc.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_event.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_state.dart';
import 'package:vishnu_enterprises/features/stock/presentation/widgets/add_stock_warehouse_modal.dart';
import 'package:vishnu_enterprises/features/stock/presentation/widgets/product_tile.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<StockBloc>().add(const StockLoadRequested());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<StockBloc>().add(StockSearchChanged(query));
    });
  }

  void _showHistoryBottomSheet(BuildContext parentContext) {
    parentContext.read<StockBloc>().add(const StockHistoryLoadRequested());

    showModalBottomSheet(
      context: parentContext,
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(modalContext);
                      },
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
                          return _StockMovementTile(movement: item)
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'fab_receive_stock_in',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(RoutePaths.receiveStock);
              },
              icon: const Icon(CupertinoIcons.barcode_viewfinder, size: 18),
              label: const Text('Receive Stock'),
              backgroundColor: Colors.green.shade600,
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'fab_add_stock_in',
              onPressed: () {
                HapticFeedback.lightImpact();
                AddStockWarehouseModal.show(context);
              },
              icon: const Icon(CupertinoIcons.paperplane_fill, size: 18),
              label: const Text('Dispatch Stock'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBarWidget(
              hintText: 'Search by name, SKU or barcode...',
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
                      onPressed: () => context.read<StockBloc>().add(
                        const StockLoadRequested(),
                      ),
                      child: const Text('Retry'),
                    ),
                  );
                }

                if (state is StockLoaded) {
                  if (state.products.isEmpty) {
                    return EmptyState(
                      title: state.searchQuery.isEmpty
                          ? 'No products found'
                          : 'No matching products',
                      message: state.searchQuery.isEmpty
                          ? 'Tap "+ Add Product" to add items to your inventory.'
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
                            onTap: () => context.push(
                              RoutePaths.editStock,
                              extra: product,
                            ),
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

class _StockMovementTile extends StatelessWidget {
  final StockMovement movement;

  const _StockMovementTile({required this.movement});

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
