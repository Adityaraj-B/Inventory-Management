import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/data/models/product.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_bloc.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_event.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_state.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_bloc.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_event.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_state.dart';
import 'package:vishnu_enterprises/data/models/shipment.dart';
import 'package:barcode_widget/barcode_widget.dart';

class AddStockWarehouseModal extends StatefulWidget {
  final String? initialWarehouseId;

  const AddStockWarehouseModal({super.key, this.initialWarehouseId});

  static void show(BuildContext context, {String? targetWarehouseId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AddStockWarehouseModal(initialWarehouseId: targetWarehouseId),
    );
  }

  @override
  State<AddStockWarehouseModal> createState() => _AddStockWarehouseModalState();
}

class _AddStockWarehouseModalState extends State<AddStockWarehouseModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _hsnController;
  late TextEditingController _priceController;
  late TextEditingController _boxesController;
  late TextEditingController _itemsPerBoxController;

  String _selectedCategory = 'Construction Materials';
  String? _selectedWarehouseId;

  final List<String> _categories = [
    'Construction Materials',
    'Steel & Metals',
    'Paints & Finishes',
    'Electricals',
    'Plumbing',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _hsnController = TextEditingController();
    _priceController = TextEditingController();
    _boxesController = TextEditingController(text: '1');
    _itemsPerBoxController = TextEditingController(text: '10');

    _selectedWarehouseId = widget.initialWarehouseId;

    // Load warehouse list if needed
    final warehouseState = context.read<WarehouseBloc>().state;
    if (warehouseState is! WarehouseLoaded) {
      context.read<WarehouseBloc>().add(const WarehouseLoadRequested());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hsnController.dispose();
    _priceController.dispose();
    _boxesController.dispose();
    _itemsPerBoxController.dispose();
    super.dispose();
  }

  int get _noOfBoxes => int.tryParse(_boxesController.text.trim()) ?? 0;
  int get _itemsPerBox => int.tryParse(_itemsPerBoxController.text.trim()) ?? 0;
  int get _totalUnits => _noOfBoxes * _itemsPerBox;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final hsnRaw = _hsnController.text.trim();
    final hsnCode = hsnRaw.toUpperCase().startsWith('HSN')
        ? hsnRaw.toUpperCase()
        : 'HSN-$hsnRaw';
    final price = double.parse(_priceController.text.trim());
    final perBox = _itemsPerBox;
    final totalUnits = _totalUnits;

    if (totalUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total units added must be greater than 0'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.isAdmin ?? true;
    final userWarehouseId =
        user?.warehouseId ?? widget.initialWarehouseId ?? 'wh-1';

    // Only admin can choose any warehouse; billing staff is strictly scoped to their assigned login warehouse
    final String targetWh = isAdmin
        ? (_selectedWarehouseId ?? widget.initialWarehouseId ?? userWarehouseId)
        : (widget.initialWarehouseId ?? userWarehouseId);

    final now = DateTime.now();
    final newProduct = Product(
      id: 'prod-${const Uuid().v4().substring(0, 8)}',
      name: name,
      sku: hsnCode,
      category: _selectedCategory,
      unitPrice: price,
      mrp: price,
      costPrice: (price * 0.8).roundToDouble(),
      quantityInStock: totalUnits,
      warehouseId: targetWh.isNotEmpty ? targetWh : 'wh-1',
      lowStockThreshold: 10,
      unitsPerBarcode: perBox > 0 ? perBox : 10,
      createdAt: now,
      updatedAt: now,
    );

    HapticFeedback.mediumImpact();

    // Dispatch add product event
    context.read<StockBloc>().add(AddProductRequested(newProduct));

    // Reload warehouse summary counts
    context.read<WarehouseBloc>().add(const WarehouseLoadRequested());

    // Removed manual pop and snackbar here, moved to BlocListener
  }

  void _showBarcodeDialog(BuildContext context, Shipment shipment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Stock Dispatched!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A new shipment has been created. Scan this barcode at the destination warehouse to receive the stock.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: shipment.id,
                width: 200,
                height: 80,
                errorBuilder: (context, error) => Center(child: Text(error)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Shipment ID: ${shipment.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Product: ${shipment.productName}'),
            Text('Quantity: ${shipment.quantity}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.isAdmin ?? true;

    return BlocListener<StockBloc, StockState>(
      listener: (context, state) {
        if (state is StockOperationSuccess && state.shipment != null) {
          Navigator.pop(context); // Close the modal
          _showBarcodeDialog(context, state.shipment!);
        } else if (state is StockError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Handle bar
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Modal Title & Target Warehouse Picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.add_business_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Stock in Warehouse',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          BlocBuilder<WarehouseBloc, WarehouseState>(
                            builder: (context, state) {
                              if (state is WarehouseLoaded) {
                                final authState = context
                                    .read<AuthBloc>()
                                    .state;
                                final user = authState is AuthAuthenticated
                                    ? authState.user
                                    : null;
                                final isAdmin = user?.isAdmin ?? true;
                                final userWhId = user?.warehouseId;
                                final currentWhId = isAdmin
                                    ? (_selectedWarehouseId ??
                                          widget.initialWarehouseId ??
                                          userWhId ??
                                          state.warehouses.first.id)
                                    : (widget.initialWarehouseId ??
                                          userWhId ??
                                          state.warehouses.first.id);
                                final currentWh = state.warehouses.firstWhere(
                                  (w) => w.id == currentWhId,
                                  orElse: () => state.warehouses.first,
                                );
                                return Text(
                                  isAdmin
                                      ? 'Target: ${currentWh.name}'
                                      : 'Target: ${currentWh.name} (Assigned Depot)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                );
                              }
                              return const Text(
                                'Adding inventory to warehouse',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Target Warehouse Selector (Admin: dropdown; Billing Staff: locked to login warehouse)
                        BlocBuilder<WarehouseBloc, WarehouseState>(
                          builder: (context, state) {
                            if (state is WarehouseLoaded) {
                              final authState = context.read<AuthBloc>().state;
                              final user = authState is AuthAuthenticated
                                  ? authState.user
                                  : null;
                              final isAdmin = user?.isAdmin ?? true;

                              if (isAdmin && state.warehouses.length > 1) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(
                                      'SELECT TARGET WAREHOUSE*',
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value:
                                              _selectedWarehouseId ??
                                              widget.initialWarehouseId ??
                                              state.warehouses.first.id,
                                          isExpanded: true,
                                          icon: const Icon(
                                            CupertinoIcons.chevron_down,
                                            size: 16,
                                          ),
                                          items: state.warehouses.map((w) {
                                            return DropdownMenuItem<String>(
                                              value: w.id,
                                              child: Text(
                                                w.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(
                                                () =>
                                                    _selectedWarehouseId = val,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              } else if (!isAdmin) {
                                final userWhId =
                                    widget.initialWarehouseId ??
                                    user?.warehouseId ??
                                    state.warehouses.first.id;
                                final currentWh = state.warehouses.firstWhere(
                                  (w) => w.id == userWhId,
                                  orElse: () => state.warehouses.first,
                                );
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(
                                      'ASSIGNED WAREHOUSE (LOCKED TO LOGIN WAREHOUSE)*',
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 18,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              currentWh.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Assigned Depot',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // 1. Item Name*
                        _buildFieldLabel('ITEM NAME*'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _inputDecoration(
                            hint: 'e.g. UltraTech Cement 50kg, TMT Bar 12mm',
                            prefixIcon: Icons.shopping_bag_outlined,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter item name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 2. HSN Code* & Category Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('HSN CODE*'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _hsnController,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: 'e.g. 2523 / 7214',
                                      prefixIcon: Icons.qr_code_2_rounded,
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Enter HSN Code';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('CATEGORY*'),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCategory,
                                        isExpanded: true,
                                        icon: const Icon(
                                          CupertinoIcons.chevron_down,
                                          size: 14,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        items: _categories.map((c) {
                                          return DropdownMenuItem<String>(
                                            value: c,
                                            child: Text(
                                              c,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedCategory = val,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 3. Price* (Per Unit)
                        _buildFieldLabel(
                          isAdmin
                              ? 'PRICE PER UNIT (₹)*'
                              : 'PRICE PER UNIT (₹) - ADMIN ONLY (LOCKED)',
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          readOnly: !isAdmin,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _inputDecoration(
                            hint: 'e.g. 380.00',
                            prefixIcon: Icons.currency_rupee_rounded,
                            suffixIcon: !isAdmin
                                ? const Icon(
                                    CupertinoIcons.lock_fill,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  )
                                : null,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter price';
                            }
                            final parsed = double.tryParse(val.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter valid positive price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 4. No. of boxes* & Number of items per box*
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('NO. OF BOXES*'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _boxesController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: 'e.g. 10',
                                      prefixIcon: Icons.inventory_2_outlined,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Enter boxes';
                                      }
                                      final p = int.tryParse(val.trim());
                                      if (p == null || p < 1) {
                                        return 'Min 1 box';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('ITEMS PER BOX*'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _itemsPerBoxController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: 'e.g. 12',
                                      prefixIcon: Icons.grid_view_rounded,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Enter items/box';
                                      }
                                      final p = int.tryParse(val.trim());
                                      if (p == null || p < 1) {
                                        return 'Min 1 item';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // â”€â”€ Real-Time Summary Card: Total Units Added â”€â”€
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.18,
                              ),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.calculate_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL UNITS ADDED',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$_totalUnits units',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '$_noOfBoxes boxes × $_itemsPerBox items per box',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        BlocBuilder<StockBloc, StockState>(
                          builder: (context, state) {
                            final isLoading = state is StockLoading;
                            return _SubmitAddButton(
                              totalUnits: _totalUnits,
                              isLoading: isLoading,
                              onTap: isLoading ? () {} : _submit,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: AppColors.textMuted,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade400,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
    );
  }
}

class _SubmitAddButton extends StatefulWidget {
  final int totalUnits;
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitAddButton({
    required this.totalUnits,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  State<_SubmitAddButton> createState() => _SubmitAddButtonState();
}

class _SubmitAddButtonState extends State<_SubmitAddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(
                  alpha: _pressed ? 0.2 : 0.35,
                ),
                blurRadius: _pressed ? 8 : 18,
                offset: Offset(0, _pressed ? 3 : 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              else
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              const SizedBox(width: 10),
              Text(
                widget.isLoading
                    ? 'Dispatching...'
                    : 'Dispatch Stock (${widget.totalUnits} Units)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
