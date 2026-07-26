import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/data/models/product.dart';
import 'package:vishnu_enterprises/features/main_layout/bloc/nav_cubit.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_bloc.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_event.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_state.dart';
import 'package:vishnu_enterprises/features/stock/presentation/widgets/barcode_preview.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_bloc.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_state.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const AddEditProductScreen({super.key, this.productToEdit});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _categoryController;
  late TextEditingController _costPriceController;
  late TextEditingController _unitPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _thresholdController;
  String _warehouseId = 'wh-1';

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(
      text: p?.sku ?? 'SKU-${const Uuid().v4().substring(0, 8).toUpperCase()}',
    );
    _categoryController = TextEditingController(text: p?.category ?? 'General');
    _costPriceController = TextEditingController(
      text: p?.costPrice.toString() ?? '100',
    );
    _unitPriceController = TextEditingController(
      text: p?.unitPrice.toString() ?? '150',
    );
    _quantityController = TextEditingController(
      text: p?.quantityInStock.toString() ?? '50',
    );
    _thresholdController = TextEditingController(
      text: p?.lowStockThreshold.toString() ?? '10',
    );
    if (p != null) {
      _warehouseId = p.warehouseId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _costPriceController.dispose();
    _unitPriceController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _navigateBackToStock(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isBilling =
        authState is AuthAuthenticated && authState.user.isBillingStaff;
    context.read<NavCubit>().selectTab(1);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(isBilling ? RoutePaths.billingStaffHome : RoutePaths.stock);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final isAdmin = user?.isAdmin ?? true;
      final effectiveWarehouseId = isAdmin
          ? _warehouseId
          : (user?.warehouseId ?? widget.productToEdit?.warehouseId ?? 'wh-1');

      final now = DateTime.now();
      final product = Product(
        id:
            widget.productToEdit?.id ??
            'prod-${const Uuid().v4().substring(0, 6)}',
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        category: _categoryController.text.trim(),
        costPrice: double.parse(_costPriceController.text),
        unitPrice: double.parse(_unitPriceController.text),
        quantityInStock: int.parse(_quantityController.text),
        warehouseId: effectiveWarehouseId,
        lowStockThreshold: int.parse(_thresholdController.text),
        createdAt: widget.productToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        context.read<StockBloc>().add(UpdateProductRequested(product));
      } else {
        context.read<StockBloc>().add(AddProductRequested(product));
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
      prefixIcon: Icon(prefixIcon, size: 20, color: Colors.grey.shade600),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.8),
      ),
    );
  }

  Widget _buildGlassCard({
    required List<Widget> children,
    String? sectionTitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sectionTitle != null) ...[
                Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.isAdmin ?? true;
    final userWhId = user?.warehouseId ?? _warehouseId;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        context.read<NavCubit>().selectTab(1);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    CupertinoIcons.chevron_left,
                    size: 18,
                    color: Colors.black87,
                  ),
                  onPressed: () => _navigateBackToStock(context),
                ),
              ),
            ),
            title: Text(
              _isEditing ? 'Edit Product' : 'Add New Product',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            centerTitle: true,
          ),
          body: BlocListener<StockBloc, StockState>(
            listener: (context, state) {
              if (state is StockOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                _navigateBackToStock(context);
              } else if (state is StockError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGlassCard(
                      children: [
                        ValueListenableBuilder(
                          valueListenable: _skuController,
                          builder: (context, value, _) {
                            return BarcodePreview(
                              productName: _nameController.text,
                              sku: _skuController.text,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGlassCard(
                      sectionTitle: 'GENERAL INFORMATION',
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _buildInputDecoration(
                            labelText: 'Product Name',
                            prefixIcon: CupertinoIcons.cube_box_fill,
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Product name is required'
                              : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _skuController,
                          readOnly: _isEditing,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isEditing
                                ? Colors.grey.shade700
                                : Colors.black87,
                          ),
                          decoration: _buildInputDecoration(
                            labelText: 'SKU / Barcode Data (Code128)',
                            prefixIcon: CupertinoIcons.barcode,
                            suffixIcon: _isEditing
                                ? const Icon(
                                    CupertinoIcons.lock_fill,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  )
                                : null,
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'SKU is required' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _categoryController,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _buildInputDecoration(
                            labelText: 'Category',
                            prefixIcon: CupertinoIcons.tag_fill,
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Category is required'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGlassCard(
                      sectionTitle: isAdmin
                          ? 'PRICING'
                          : 'PRICING (ADMIN ONLY - LOCKED)',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _costPriceController,
                                readOnly: !isAdmin,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: _buildInputDecoration(
                                  labelText: 'Cost Price (â‚¹)',
                                  prefixIcon: Icons.currency_rupee,
                                  suffixIcon: !isAdmin
                                      ? const Icon(
                                          CupertinoIcons.lock_fill,
                                          size: 16,
                                          color: AppColors.textMuted,
                                        )
                                      : null,
                                ),
                                validator: (v) =>
                                    v == null || double.tryParse(v) == null
                                    ? 'Invalid cost'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _unitPriceController,
                                readOnly: !isAdmin,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: _buildInputDecoration(
                                  labelText: 'Selling Price (â‚¹)',
                                  prefixIcon:
                                      Icons.currency_rupee,
                                  suffixIcon: !isAdmin
                                      ? const Icon(
                                          CupertinoIcons.lock_fill,
                                          size: 16,
                                          color: AppColors.textMuted,
                                        )
                                      : null,
                                ),
                                validator: (v) =>
                                    v == null || double.tryParse(v) == null
                                    ? 'Invalid price'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGlassCard(
                      sectionTitle: 'INVENTORY & LOCATION',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: _buildInputDecoration(
                                  labelText: 'Stock Qty',
                                  prefixIcon: CupertinoIcons.number,
                                ),
                                validator: (v) =>
                                    v == null || int.tryParse(v) == null
                                    ? 'Invalid quantity'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _thresholdController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: _buildInputDecoration(
                                  labelText: 'Low Stock Limit',
                                  prefixIcon: CupertinoIcons.bell_fill,
                                ),
                                validator: (v) =>
                                    v == null || int.tryParse(v) == null
                                    ? 'Invalid limit'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        BlocBuilder<WarehouseBloc, WarehouseState>(
                          builder: (context, state) {
                            if (state is WarehouseLoaded) {
                              if (isAdmin) {
                                final currentVal =
                                    state.warehouses.any(
                                      (w) => w.id == _warehouseId,
                                    )
                                    ? _warehouseId
                                    : state.warehouses.first.id;
                                return DropdownButtonFormField<String>(
                                  initialValue: currentVal,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  decoration: _buildInputDecoration(
                                    labelText: 'Assigned Warehouse',
                                    prefixIcon: CupertinoIcons.building_2_fill,
                                  ),
                                  items: state.warehouses.map((w) {
                                    return DropdownMenuItem<String>(
                                      value: w.id,
                                      child: Text(w.name),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _warehouseId = v);
                                    }
                                  },
                                );
                              } else {
                                final currentWh = state.warehouses.firstWhere(
                                  (w) => w.id == userWhId,
                                  orElse: () => state.warehouses.first,
                                );
                                return Container(
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
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ASSIGNED WAREHOUSE (LOCKED TO LOGIN WAREHOUSE)',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.grey.shade600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              currentWh.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.85),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _submitForm,
                          borderRadius: BorderRadius.circular(18),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isEditing
                                      ? CupertinoIcons.checkmark_alt
                                      : CupertinoIcons.add,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isEditing
                                      ? 'Save Product Changes'
                                      : 'Confirm & Save Product',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
