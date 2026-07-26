import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/widgets/empty_state.dart';
import 'package:vishnu_enterprises/core/widgets/loading_indicator.dart';
import 'package:vishnu_enterprises/core/widgets/search_bar_widget.dart';
import 'package:vishnu_enterprises/data/models/product.dart';
import 'package:vishnu_enterprises/data/models/warehouse.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_bloc.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_event.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_state.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_bloc.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_event.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_state.dart';

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  String? _selectedDestinationWarehouseId;
  String? _selectedSourceWarehouseId;
  String _searchQuery = '';
  bool _initializedDefaults = false;

  @override
  void initState() {
    super.initState();
    // Load warehouses & all stock products
    context.read<WarehouseBloc>().add(const WarehouseLoadRequested());
    context.read<StockBloc>().add(const StockLoadRequested());
  }

  void _initDefaultWarehouses(List<Warehouse> warehouses) {
    if (_initializedDefaults || warehouses.isEmpty) return;
    _initializedDefaults = true;

    final authState = context.read<AuthBloc>().state;
    final userWarehouseId = authState is AuthAuthenticated
        ? authState.user.warehouseId
        : null;

    // Default destination warehouse to user's assigned warehouse if valid, else first active warehouse
    Warehouse? defaultDestination;
    if (userWarehouseId != null &&
        warehouses.any((w) => w.id == userWarehouseId)) {
      defaultDestination = warehouses.firstWhere(
        (w) => w.id == userWarehouseId,
      );
    } else {
      defaultDestination = warehouses.firstWhere(
        (w) => w.isActive,
        orElse: () => warehouses.first,
      );
    }

    _selectedDestinationWarehouseId = defaultDestination.id;

    // Default source warehouse to the first warehouse that is not destination
    final otherWarehouses = warehouses
        .where((w) => w.id != _selectedDestinationWarehouseId)
        .toList();
    if (otherWarehouses.isNotEmpty) {
      _selectedSourceWarehouseId = otherWarehouses.first.id;
    }
  }

  void _onSwitchDestinationWarehouse(
    String newDestinationId,
    List<Warehouse> allWarehouses,
  ) {
    setState(() {
      _selectedDestinationWarehouseId = newDestinationId;
      if (_selectedSourceWarehouseId == newDestinationId) {
        final otherWarehouses = allWarehouses
            .where((w) => w.id != newDestinationId)
            .toList();
        _selectedSourceWarehouseId = otherWarehouses.isNotEmpty
            ? otherWarehouses.first.id
            : null;
      }
    });
  }

  void _showTransferModal(
    BuildContext context, {
    required Product sourceProduct,
    required Warehouse sourceWarehouse,
    required Warehouse destinationWarehouse,
    required int currentDestinationQty,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransferQuantityModal(
        sourceProduct: sourceProduct,
        sourceWarehouse: sourceWarehouse,
        destinationWarehouse: destinationWarehouse,
        currentDestinationQty: currentDestinationQty,
        onConfirm: (int quantity) {
          context.read<StockBloc>().add(
            TransferStockRequested(
              sourceProductId: sourceProduct.id,
              sourceWarehouseId: sourceWarehouse.id,
              targetWarehouseId: destinationWarehouse.id,
              quantity: quantity,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Stock Transfer',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CircularIconButton(
              icon: CupertinoIcons.refresh,
              color: theme.colorScheme.primary,
              tooltip: 'Refresh Warehouses & Stock',
              onTap: () {
                HapticFeedback.lightImpact();
                HapticFeedback.selectionClick();
                context.read<WarehouseBloc>().add(
                  const WarehouseLoadRequested(),
                );
                context.read<StockBloc>().add(const StockLoadRequested());
              },
            ),
          ),
        ],
      ),
      body: BlocListener<StockBloc, StockState>(
        listener: (context, state) {
          if (state is StockOperationSuccess) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            // Refresh warehouse list counts after transfer
            context.read<WarehouseBloc>().add(const WarehouseLoadRequested());
          } else if (state is StockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<WarehouseBloc, WarehouseState>(
          builder: (context, warehouseState) {
            if (warehouseState is WarehouseLoading) {
              return const LoadingIndicator(
                message: 'Loading warehouse inventory...',
              );
            }

            if (warehouseState is WarehouseError) {
              return EmptyState(
                title: 'Error loading warehouses',
                message: warehouseState.message,
                action: ElevatedButton(
                  onPressed: () => context.read<WarehouseBloc>().add(
                    const WarehouseLoadRequested(),
                  ),
                  child: const Text('Retry'),
                ),
              );
            }

            if (warehouseState is WarehouseLoaded) {
              final allWarehouses = warehouseState.warehouses;
              if (allWarehouses.isEmpty) {
                return const EmptyState(
                  title: 'No Warehouses',
                  message: 'Create a warehouse to transfer stock.',
                );
              }

              _initDefaultWarehouses(allWarehouses);

              final destId = _selectedDestinationWarehouseId;
              final sourceId = _selectedSourceWarehouseId;

              final destWarehouse = allWarehouses.firstWhere(
                (w) => w.id == destId,
                orElse: () => allWarehouses.first,
              );

              final otherWarehouses = allWarehouses
                  .where((w) => w.id != destWarehouse.id)
                  .toList();

              final sourceWarehouse = otherWarehouses.firstWhere(
                (w) => w.id == sourceId,
                orElse: () => otherWarehouses.isNotEmpty
                    ? otherWarehouses.first
                    : destWarehouse,
              );

              return Column(
                children: [
                  // â”€â”€ Top Bar: Destination & Source Warehouse selector â”€â”€
                  _buildWarehouseSelectorHeader(
                    context,
                    destWarehouse: destWarehouse,
                    sourceWarehouse: sourceWarehouse,
                    allWarehouses: allWarehouses,
                    otherWarehouses: otherWarehouses,
                  ),

                  // â”€â”€ Search Bar â”€â”€
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SearchBarWidget(
                        hintText: 'Search stock in ${sourceWarehouse.name}...',
                        onChanged: (q) => setState(() => _searchQuery = q),
                      ),
                    ),
                  ),

                  // â”€â”€ Product List from Source Warehouse â”€â”€
                  Expanded(
                    child: BlocBuilder<StockBloc, StockState>(
                      builder: (context, stockState) {
                        if (stockState is StockLoading) {
                          return const LoadingIndicator(
                            message: 'Loading warehouse products...',
                          );
                        }

                        if (stockState is StockLoaded) {
                          final allProducts = stockState.products;

                          // Products present in source warehouse
                          final sourceProducts = allProducts.where((p) {
                            if (p.warehouseId != sourceWarehouse.id) {
                              return false;
                            }
                            if (_searchQuery.isNotEmpty) {
                              final q = _searchQuery.toLowerCase();
                              return p.name.toLowerCase().contains(q) ||
                                  p.sku.toLowerCase().contains(q) ||
                                  p.category.toLowerCase().contains(q);
                            }
                            return true;
                          }).toList();

                          if (otherWarehouses.isEmpty) {
                            return const EmptyState(
                              title: 'Only 1 Warehouse',
                              message:
                                  'You need at least two warehouses to perform stock transfers.',
                            );
                          }

                          if (sourceProducts.isEmpty) {
                            return EmptyState(
                              title: 'No Stock Found',
                              message: _searchQuery.isEmpty
                                  ? 'No items in ${sourceWarehouse.name} to transfer.'
                                  : 'No products match "$_searchQuery" in ${sourceWarehouse.name}.',
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: sourceProducts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final product = sourceProducts[index];

                              // Find how much of this SKU currently exists in target warehouse
                              final targetMatch = allProducts.firstWhere(
                                (p) =>
                                    p.warehouseId == destWarehouse.id &&
                                    p.sku == product.sku,
                                orElse: () => Product(
                                  id: '',
                                  name: '',
                                  sku: '',
                                  category: '',
                                  unitPrice: 0,
                                  costPrice: 0,
                                  quantityInStock: 0,
                                  warehouseId: destWarehouse.id,
                                  lowStockThreshold: 0,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              );

                              final currentDestQty = targetMatch.id.isNotEmpty
                                  ? targetMatch.quantityInStock
                                  : 0;

                              return _buildProductTransferCard(
                                    context,
                                    product: product,
                                    sourceWarehouse: sourceWarehouse,
                                    destWarehouse: destWarehouse,
                                    currentDestQty: currentDestQty,
                                  )
                                  .animate(delay: (25 * (index % 12)).ms)
                                  .fade(duration: 260.ms)
                                  .slideY(begin: 0.05, end: 0);
                            },
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildWarehouseSelectorHeader(
    BuildContext context, {
    required Warehouse destWarehouse,
    required Warehouse sourceWarehouse,
    required List<Warehouse> allWarehouses,
    required List<Warehouse> otherWarehouses,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Target / Destination Warehouse Row â”€â”€
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warehouse_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECEIVING WAREHOUSE (THIS WAREHOUSE)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destWarehouse.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _PillActionButton(
                icon: CupertinoIcons.arrow_2_circlepath,
                label: 'Change',
                color: AppColors.accent,
                onTap: () => _showChangeDestinationModal(
                  context,
                  currentDestId: destWarehouse.id,
                  warehouses: allWarehouses,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // â”€â”€ Source / Other Warehouses Section â”€â”€
          Text(
            'SELECT SOURCE WAREHOUSE (OTHER WAREHOUSES)',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 9),

          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: otherWarehouses.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final w = otherWarehouses[index];
                final isSelected = w.id == sourceWarehouse.id;

                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedSourceWarehouseId = w.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.fastLinearToSlowEaseIn,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.shade300,
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 
                                  0.26,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          w.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeDestinationModal(
    BuildContext context, {
    required String currentDestId,
    required List<Warehouse> warehouses,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Receiving Warehouse',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'All incoming stock transfers will be credited to this warehouse.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...warehouses.map((w) {
                  final isCurrent = w.id == currentDestId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isCurrent
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      child: Icon(
                        Icons.warehouse_rounded,
                        color: isCurrent
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      w.name,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      w.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      _onSwitchDestinationWarehouse(w.id, warehouses);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductTransferCard(
    BuildContext context, {
    required Product product,
    required Warehouse sourceWarehouse,
    required Warehouse destWarehouse,
    required int currentDestQty,
  }) {
    final theme = Theme.of(context);
    final canTransfer = product.quantityInStock > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Product name + Category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            product.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'SKU: ${product.sku}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: canTransfer
                      ? Colors.orange.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: canTransfer
                        ? Colors.orange.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'AVAILABLE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: canTransfer
                            ? Colors.orange.shade900
                            : Colors.grey.shade600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      '${product.quantityInStock} units',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: canTransfer
                            ? Colors.orange.shade900
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade100, thickness: 1.2),
          const SizedBox(height: 14),

          // Footer Row: Current Target Stock + Transfer Button
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 16,
                      color: currentDestQty > 0
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'In ${destWarehouse.name}: $currentDestQty units',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: currentDestQty > 0
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TransferButton(
                enabled: canTransfer,
                onTap: canTransfer
                    ? () => _showTransferModal(
                        context,
                        sourceProduct: product,
                        sourceWarehouse: sourceWarehouse,
                        destinationWarehouse: destWarehouse,
                        currentDestinationQty: currentDestQty,
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Small floating circular icon button used in the app bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CircularIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _CircularIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_CircularIconButton> createState() => _CircularIconButtonState();
}

class _CircularIconButtonState extends State<_CircularIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastLinearToSlowEaseIn,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 18, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Tinted pill button (used for the "Change" destination action) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PillActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PillActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PillActionButton> createState() => _PillActionButtonState();
}

class _PillActionButtonState extends State<_PillActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastLinearToSlowEaseIn,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: widget.color),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Transfer action button on the product card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TransferButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _TransferButton({required this.enabled, required this.onTap});

  @override
  State<_TransferButton> createState() => _TransferButtonState();
}

class _TransferButtonState extends State<_TransferButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastLinearToSlowEaseIn,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: widget.enabled
                ? Colors.orange.shade800
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(13),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: _pressed ? 0.16 : 0.32),
                      blurRadius: _pressed ? 6 : 12,
                      offset: Offset(0, _pressed ? 2 : 5),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 18,
                color: widget.enabled ? Colors.white : Colors.grey.shade400,
              ),
              const SizedBox(width: 6),
              Text(
                'Transfer',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.enabled ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Interactive Quantity Selection Modal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TransferQuantityModal extends StatefulWidget {
  final Product sourceProduct;
  final Warehouse sourceWarehouse;
  final Warehouse destinationWarehouse;
  final int currentDestinationQty;
  final ValueChanged<int> onConfirm;

  const _TransferQuantityModal({
    required this.sourceProduct,
    required this.sourceWarehouse,
    required this.destinationWarehouse,
    required this.currentDestinationQty,
    required this.onConfirm,
  });

  @override
  State<_TransferQuantityModal> createState() => _TransferQuantityModalState();
}

class _TransferQuantityModalState extends State<_TransferQuantityModal> {
  late final TextEditingController _qtyController;
  int _quantity = 1;
  String? _errorText;

  int get _maxAvailable => widget.sourceProduct.quantityInStock;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '$_quantity');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _updateQuantity(int val) {
    final clamped = math.max(1, math.min(val, _maxAvailable));
    setState(() {
      _quantity = clamped;
      _qtyController.text = '$_quantity';
      _errorText = null;
    });
  }

  void _onManualInput(String text) {
    final parsed = int.tryParse(text);
    setState(() {
      if (parsed == null || parsed <= 0) {
        _errorText = 'Enter a valid quantity > 0';
      } else if (parsed > _maxAvailable) {
        _errorText = 'Max available is $_maxAvailable units';
      } else {
        _quantity = parsed;
        _errorText = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid =
        _errorText == null && _quantity > 0 && _quantity <= _maxAvailable;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.orange.shade800,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transfer Stock',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.sourceProduct.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // â”€â”€ Warehouse Flow Preview Box â”€â”€
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  // Source
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FROM (${widget.sourceWarehouse.name})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.sourceProduct.quantityInStock - (isValid ? _quantity : 0)} units',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '-$_quantity transferred',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  // Destination
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TO (${widget.destinationWarehouse.name})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.currentDestinationQty + (isValid ? _quantity : 0)} units',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '+$_quantity received',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // â”€â”€ Quantity Stepper & Input â”€â”€
            const Text(
              'SELECT TRANSFER QUANTITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StepperButton(
                  icon: CupertinoIcons.minus,
                  onTap: _quantity > 1
                      ? () => _updateQuantity(_quantity - 1)
                      : null,
                ),
                const SizedBox(width: 8),
                _StepperButton(
                  label: '-10',
                  onTap: _quantity > 1
                      ? () => _updateQuantity(_quantity - 10)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      errorText: _errorText,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: _onManualInput,
                  ),
                ),
                const SizedBox(width: 12),
                _StepperButton(
                  label: '+10',
                  onTap: _quantity < _maxAvailable
                      ? () => _updateQuantity(_quantity + 10)
                      : null,
                ),
                const SizedBox(width: 8),
                _StepperButton(
                  icon: CupertinoIcons.add,
                  onTap: _quantity < _maxAvailable
                      ? () => _updateQuantity(_quantity + 1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Max available: $_maxAvailable units',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => _updateQuantity(_maxAvailable),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.orange.shade800,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Transfer Max'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // â”€â”€ Confirm Transfer Button â”€â”€
            _ConfirmTransferButton(
              quantity: _quantity,
              enabled: isValid,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                widget.onConfirm(_quantity);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Numeric stepper control button in the transfer modal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StepperButton extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;

  const _StepperButton({this.icon, this.label, this.onTap});

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastLinearToSlowEaseIn,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? Colors.grey.shade100 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
            ),
          ),
          child: widget.icon != null
              ? Icon(
                  widget.icon,
                  size: 18,
                  color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                )
              : Text(
                  widget.label ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
        ),
      ),
    );
  }
}

// â”€â”€ Full-width confirm button for the transfer modal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ConfirmTransferButton extends StatefulWidget {
  final int quantity;
  final bool enabled;
  final VoidCallback onTap;

  const _ConfirmTransferButton({
    required this.quantity,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ConfirmTransferButton> createState() => _ConfirmTransferButtonState();
}

class _ConfirmTransferButtonState extends State<_ConfirmTransferButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTap: widget.enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastLinearToSlowEaseIn,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.enabled
                ? Colors.orange.shade800
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: _pressed ? 0.18 : 0.34),
                      blurRadius: _pressed ? 10 : 18,
                      offset: Offset(0, _pressed ? 4 : 8),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_rounded,
                size: 20,
                color: widget.enabled ? Colors.white : Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                'Confirm Transfer (${widget.quantity} units)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.enabled ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
