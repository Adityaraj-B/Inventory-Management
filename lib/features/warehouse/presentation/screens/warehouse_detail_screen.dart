import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/widgets/empty_state.dart';
import 'package:vishnu_enterprises/core/widgets/loading_indicator.dart';
import 'package:vishnu_enterprises/data/models/product.dart';
import 'package:vishnu_enterprises/data/models/warehouse.dart';
import 'package:vishnu_enterprises/features/stock/presentation/widgets/product_tile.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_bloc.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_event.dart';
import 'package:vishnu_enterprises/features/warehouse/bloc/warehouse_state.dart';
import 'package:vishnu_enterprises/injection.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final Warehouse warehouse;

  const WarehouseDetailScreen({super.key, required this.warehouse});

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _contactCtrl;
  late bool _isActive;

  bool _hasUnsavedChanges = false;
  List<Product> _stockedProducts = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.warehouse.name);
    _addressCtrl = TextEditingController(text: widget.warehouse.address);
    _contactCtrl = TextEditingController(text: widget.warehouse.contactPerson);
    _isActive = widget.warehouse.isActive;
    _fetchStockedProducts();
  }

  Future<void> _fetchStockedProducts() async {
    try {
      final products = await getIt.productRepository.getProducts(
        warehouseId: widget.warehouse.id,
      );
      if (mounted) {
        setState(() {
          _stockedProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _saveWarehouse() {
    if (_formKey.currentState!.validate()) {
      final updated = widget.warehouse.copyWith(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        contactPerson: _contactCtrl.text.trim(),
        isActive: _isActive,
      );
      context.read<WarehouseBloc>().add(UpdateWarehouseRequested(updated));
      setState(() => _hasUnsavedChanges = false);
      FocusScope.of(context).unfocus();
    }
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade500,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
      prefixIcon: Icon(icon, size: 22, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F6F9),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: IconButton(
                icon: const Icon(
                  CupertinoIcons.arrow_left,
                  size: 18,
                  color: Colors.black87,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          title: Column(
            children: [
              Text(
                widget.warehouse.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Warehouse Details',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          actions: [
            AnimatedOpacity(
              opacity: _hasUnsavedChanges ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton.icon(
                  onPressed: _hasUnsavedChanges ? _saveWarehouse : null,
                  icon: const Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: BlocListener<WarehouseBloc, WarehouseState>(
          listener: (context, state) {
            if (state is WarehouseOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              );
            } else if (state is WarehouseError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              );
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: _hasUnsavedChanges
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFFFEDD5),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withValues(alpha: 
                                            0.05,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFFEDD5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.info_circle_fill,
                                            color: Color(0xFFEA580C),
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 2),
                                            child: Text(
                                              'You have unsaved changes. Tap "Save Changes" to apply.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF9A3412),
                                                fontWeight: FontWeight.w600,
                                                height: 1.5,
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        Form(
                          key: _formKey,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 
                                    0.04,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 16,
                                  sigmaY: 16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.95),
                                        Colors.white.withValues(alpha: 0.75),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.12),
                                              ),
                                            ),
                                            child: Icon(
                                              CupertinoIcons.building_2_fill,
                                              color: theme.colorScheme.primary,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Metadata & Status',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black87,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        child: Divider(
                                          height: 1,
                                          color: Color(0xFFE5E7EB),
                                          thickness: 1.5,
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _nameCtrl,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        onChanged: (_) => _markChanged(),
                                        decoration: _buildInputDecoration(
                                          context,
                                          label: 'Warehouse Name',
                                          icon: CupertinoIcons.tag_fill,
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _addressCtrl,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        onChanged: (_) => _markChanged(),
                                        decoration: _buildInputDecoration(
                                          context,
                                          label: 'Full Address',
                                          icon: CupertinoIcons.map_pin_ellipse,
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _contactCtrl,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        onChanged: (_) => _markChanged(),
                                        decoration: _buildInputDecoration(
                                          context,
                                          label: 'Contact Person & Phone',
                                          icon: CupertinoIcons
                                              .person_crop_circle_fill,
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                      const SizedBox(height: 24),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8F9FA),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Operational Status',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _isActive
                                                        ? Colors.green.shade50
                                                        : Colors.red.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _isActive
                                                        ? 'ACTIVE'
                                                        : 'INACTIVE',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 0.5,
                                                      color: _isActive
                                                          ? Colors
                                                                .green
                                                                .shade700
                                                          : Colors.red.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            CupertinoSwitch(
                                              value: _isActive,
                                              activeTrackColor:
                                                  theme.colorScheme.primary,
                                              onChanged: (val) {
                                                setState(() => _isActive = val);
                                                _markChanged();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),

                                      AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.fastLinearToSlowEaseIn,
                                        child: _hasUnsavedChanges
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 24,
                                                ),
                                                child: Container(
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        theme
                                                            .colorScheme
                                                            .primary
                                                            .withValues(alpha: 0.85),
                                                        theme
                                                            .colorScheme
                                                            .primary,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme
                                                            .colorScheme
                                                            .primary
                                                            .withValues(alpha: 0.35),
                                                        blurRadius: 16,
                                                        offset: const Offset(
                                                          0,
                                                          8,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      onTap: _saveWarehouse,
                                                      child: const Center(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              CupertinoIcons
                                                                  .checkmark_seal_fill,
                                                              size: 20,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Save Changes',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                letterSpacing:
                                                                    -0.3,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'STOCKED PRODUCTS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_stockedProducts.length} Items',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_isLoadingProducts)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: LoadingIndicator(
                                message: 'Fetching inventory...',
                              ),
                            ),
                          )
                        else if (_stockedProducts.isEmpty)
                          const EmptyState(
                            title: 'No products in this warehouse',
                            message:
                                'Products assigned to this depot will list here.',
                            icon: CupertinoIcons.cube_box_fill,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _stockedProducts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return ProductTile(
                                product: _stockedProducts[index],
                              );
                            },
                          ),
                      ]
                      .animate(interval: 50.ms)
                      .fade(duration: 400.ms)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.fastLinearToSlowEaseIn,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
