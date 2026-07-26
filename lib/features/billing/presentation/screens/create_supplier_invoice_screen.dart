import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/data/models/supplier.dart';
import 'package:vishnu_enterprises/data/models/supplier_invoice.dart';
import 'package:vishnu_enterprises/data/models/supplier_item.dart';
import 'package:vishnu_enterprises/data/models/supplier_invoice_line_item.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/injection.dart';

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: Colors.grey.shade500,
    ),
    floatingLabelStyle: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: primary,
    ),
    prefixIcon: Icon(icon, size: 19, color: Colors.grey.shade400),
    prefixIconConstraints: const BoxConstraints(minWidth: 46),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
    ),
  );
}

class CreateSupplierInvoiceScreen extends StatefulWidget {
  final Supplier? supplier;

  const CreateSupplierInvoiceScreen({super.key, this.supplier});

  @override
  State<CreateSupplierInvoiceScreen> createState() =>
      _CreateSupplierInvoiceScreenState();
}

class _CreateSupplierInvoiceScreenState
    extends State<CreateSupplierInvoiceScreen> {
  int _currentStep = 0; // 0 = add items, 1 = review

  final List<_LineItemDraft> _lineItems = [];
  List<SupplierItem> _existingItems = [];
  bool _isLoadingItems = true;

  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final randomId = const Uuid().v4().substring(0, 6).toUpperCase();
    _invoiceNumberController.text = 'SUP-INV-$randomId';

    if (widget.supplier != null) {
      _loadSupplierItems();
    }
  }

  Future<void> _loadSupplierItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final items = await getIt.supplierRepository.getSupplierItems(
        widget.supplier!.id,
      );
      if (mounted) {
        setState(() {
          _existingItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingItems = false);
      }
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _warehouseId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.warehouseId ?? 'wh-1';
    }
    return 'wh-1';
  }

  double get _totalInvoiceAmount =>
      _lineItems.fold(0.0, (sum, li) => sum + li.lineTotal);

  void _goToStep(int step) {
    setState(() => _currentStep = step);
  }

  Future<void> _saveInvoice() async {
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }

    if (widget.supplier == null) return;

    setState(() => _isSaving = true);

    try {
      final invoice = SupplierInvoice(
        id: 'inv-${const Uuid().v4()}',
        supplierId: widget.supplier!.id,
        warehouseId: _warehouseId,
        invoiceNumber: _invoiceNumberController.text.trim(),
        totalAmount: _totalInvoiceAmount,
        paymentStatus: PaymentStatus.credit,
        date: DateTime.now(),
        notes: _notesController.text.trim(),
        lineItems: _lineItems
            .map(
              (draft) => SupplierInvoiceLineItem(
                supplierItemId: draft.supplierItemId,
                itemName: draft.itemName,
                costPrice: draft.costPrice,
                numBoxes: draft.numBoxes,
                numUnits: draft.numUnits,
                costPerUnit: draft.costPerUnit,
                lineTotal: draft.lineTotal,
              ),
            )
            .toList(),
      );

      await getIt.supplierRepository.createSupplierInvoice(invoice);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Supplier invoice created successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(RoutePaths.billingSupplierInvoices);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.supplier == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No supplier selected')),
      );
    }

    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F6F8),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            _currentStep == 0 ? 'Add Invoice Items' : 'Review Invoice',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: _currentStep >= 1
                            ? theme.colorScheme.primary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentStep,
          children: [_buildAddItems(), _buildReview()],
        ),
      ),
    );
  }

  Widget _buildAddItems() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Supplier header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.primary.withValues(alpha: 0.14),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.building_2_fill,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.supplier!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_lineItems.length} item${_lineItems.length != 1 ? 's' : ''} added  â€¢  Total: â‚¹${NumberFormat('#,##,##0.00').format(_totalInvoiceAmount)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Add item actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _OutlinedActionButton(
                  label: 'From Catalog',
                  icon: CupertinoIcons.list_bullet,
                  color: theme.colorScheme.primary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showSelectExistingItemSheet(_existingItems);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrimaryActionButton(
                  label: 'New Item',
                  icon: CupertinoIcons.add,
                  color: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showAddNewItemSheet();
                  },
                ),
              ),
            ],
          ),
        ),

        // Line items list
        Expanded(
          child: _isLoadingItems
              ? const Center(child: CircularProgressIndicator())
              : _lineItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.cart,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No items added yet',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add items from catalog or create new ones',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _lineItems.length,
                  itemBuilder: (context, index) {
                    final li = _lineItems[index];
                    return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      li.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _lineItems.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.08,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.clear_thick,
                                        size: 13,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _lineItems.removeAt(index);
                                    });
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildMiniStat('Boxes', li.numBoxes.toString()),
                                _buildMiniStat(
                                  'Units/Box',
                                  li.numUnits.toString(),
                                ),
                                _buildMiniStat(
                                  'Cost/Unit',
                                  '₹${li.costPerUnit.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Line Total',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
=======
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildMiniStat(
                                    'Boxes',
                                    li.numBoxes.toString(),
>>>>>>> 08f86ab (Fixed Bugs and Added Haptics)
                                  ),
                                  _buildMiniStat(
                                    'Units/Box',
                                    li.numUnits.toString(),
                                  ),
                                  _buildMiniStat(
                                    'Cost/Unit',
                                    'â‚¹${li.costPerUnit.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: Colors.grey.shade100,
                                  thickness: 1.2,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Line Total',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'â‚¹${NumberFormat('#,##,##0.00').format(li.lineTotal)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        .animate(delay: (30 * (index % 12)).ms)
                        .fade(duration: 250.ms)
                        .slideY(begin: 0.05, end: 0);
                  },
                ),
        ),

        // Bottom: proceed to review
        if (_lineItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Invoice Total',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'â‚¹${NumberFormat('#,##,##0.00').format(_totalInvoiceAmount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PrimaryActionButton(
                    label: 'Review Invoice',
                    color: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    onTap: () => _goToStep(1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showSelectExistingItemSheet(List<SupplierItem> items) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No items in this supplier\'s catalog. Create a new one.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Select Item from Catalog',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _CatalogItemTile(
                          item: item,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            _showLineItemDetailsSheet(
                              supplierItemId: item.id,
                              itemName: item.name,
                              defaultCostPrice: item.costPrice,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddNewItemSheet() {
    final nameCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create New Supplier Item',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: _fieldDecoration(
                    context,
                    label: 'Item Name *',
                    icon: CupertinoIcons.cube_box,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: costCtrl,
                  decoration: _fieldDecoration(
                    context,
                    label: 'Cost Price (â‚¹)',
                    icon: Icons.currency_rupee,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 24),
                _PrimaryActionButton(
                  label: 'Create & Add to Invoice',
                  color: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onTap: () async {
                    if (!formKey.currentState!.validate()) return;

                    try {
                      final item = SupplierItem(
                        id: 'item-${const Uuid().v4().substring(0, 6)}',
                        supplierId: widget.supplier!.id,
                        name: nameCtrl.text.trim(),
                        costPrice: double.tryParse(costCtrl.text.trim()) ?? 0.0,
                      );

                      final created = await getIt.supplierRepository
                          .addSupplierItem(item);

                      setState(() {
                        _existingItems.add(created);
                      });

                      if (ctx.mounted) Navigator.of(ctx).pop();

                      _showLineItemDetailsSheet(
                        supplierItemId: created.id,
                        itemName: created.name,
                        defaultCostPrice: created.costPrice,
                      );
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Failed to add item')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLineItemDetailsSheet({
    required String supplierItemId,
    required String itemName,
    required double defaultCostPrice,
  }) {
    final boxesCtrl = TextEditingController();
    final unitsCtrl = TextEditingController();
    final costPerUnitCtrl = TextEditingController(
      text: defaultCostPrice.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final boxes = int.tryParse(boxesCtrl.text) ?? 0;
            final units = int.tryParse(unitsCtrl.text) ?? 0;
            final costPerUnit = double.tryParse(costPerUnitCtrl.text) ?? 0.0;
            final totalUnits = boxes * units;
            final lineTotal = totalUnits * costPerUnit;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: boxesCtrl,
                            decoration: _fieldDecoration(
                              context,
                              label: 'No. of Boxes *',
                              icon: CupertinoIcons.cube_box,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: unitsCtrl,
                            decoration: _fieldDecoration(
                              context,
                              label: 'Units/Box *',
                              icon: CupertinoIcons.square_grid_2x2,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: costPerUnitCtrl,
                      decoration: _fieldDecoration(
                        context,
                        label: 'Cost per Unit (â‚¹) *',
                        icon: Icons.currency_rupee,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setSheetState(() {}),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Units',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$totalUnits',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Line Total',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'â‚¹${NumberFormat('#,##,##0.00').format(lineTotal)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PrimaryActionButton(
                      label: 'Add to Invoice',
                      color: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onTap: () {
                        if (!formKey.currentState!.validate()) return;

                        setState(() {
                          _lineItems.add(
                            _LineItemDraft(
                              supplierItemId: supplierItemId,
                              itemName: itemName,
                              costPrice: defaultCostPrice,
                              numBoxes: boxes,
                              numUnits: units,
                              costPerUnit: costPerUnit,
                              lineTotal: lineTotal,
                            ),
                          );
                        });

                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReview() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Supplier info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          CupertinoIcons.building_2_fill,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.supplier!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.supplier!.phone.isNotEmpty)
                              Text(
                                widget.supplier!.phone,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _invoiceNumberController,
                  decoration: _fieldDecoration(
                    context,
                    label: 'Invoice Number (optional)',
                    icon: CupertinoIcons.doc_text,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  decoration: _fieldDecoration(
                    context,
                    label: 'Notes (optional)',
                    icon: CupertinoIcons.text_alignleft,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Items Review',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _goToStep(0),
                      child: const Text(
                        'Edit Items',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._lineItems.map(
                  (li) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                li.itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${li.numBoxes} boxes Ã— ${li.numUnits} units Ã— â‚¹${li.costPerUnit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'â‚¹${NumberFormat('#,##,##0.00').format(li.lineTotal)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80), // padding for bottom bar
              ],
            ),
          ),
        ),

        // Bottom CTA
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'â‚¹${NumberFormat('#,##,##0.00').format(_totalInvoiceAmount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                _PrimaryActionButton(
                  label: 'Save Invoice',
                  color: theme.colorScheme.primary,
                  isLoading: _isSaving,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  onTap: _isSaving ? null : _saveInvoice,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Gradient press-animated action button, used across the whole flow â”€â”€â”€â”€â”€â”€
class _PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const _PrimaryActionButton({
    required this.label,
    this.icon,
    required this.color,
    this.isLoading = false,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled
                ? LinearGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.88),
                      widget.color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : Colors.grey.shade300,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: widget.color.withValues(
                        alpha: _pressed ? 0.18 : 0.32,
                      ),
                      blurRadius: _pressed ? 8 : 16,
                      offset: Offset(0, _pressed ? 3 : 7),
                    ),
                  ]
                : [],
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 17,
                        color: enabled ? Colors.white : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: enabled ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// â”€â”€ Tinted outlined action button (secondary action, e.g. "From Catalog") â”€â”€
class _OutlinedActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlinedActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_OutlinedActionButton> createState() => _OutlinedActionButtonState();
}

class _OutlinedActionButtonState extends State<_OutlinedActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _pressed ? 0.1 : 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13.5,
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

// â”€â”€ Catalog item row in the "select existing item" sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CatalogItemTile extends StatefulWidget {
  final SupplierItem item;
  final Color color;
  final VoidCallback onTap;

  const _CatalogItemTile({
    required this.item,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CatalogItemTile> createState() => _CatalogItemTileState();
}

class _CatalogItemTileState extends State<_CatalogItemTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      CupertinoIcons.cube_box,
                      size: 20,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cost: â‚¹${widget.item.costPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineItemDraft {
  final String supplierItemId;
  final String itemName;
  final double costPrice;
  final int numBoxes;
  final int numUnits;
  final double costPerUnit;
  final double lineTotal;

  const _LineItemDraft({
    required this.supplierItemId,
    required this.itemName,
    required this.costPrice,
    required this.numBoxes,
    required this.numUnits,
    required this.costPerUnit,
    required this.lineTotal,
  });
}
