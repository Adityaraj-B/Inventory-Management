import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/supplier.dart';
import '../../../../injection.dart';

/// A modal dialog for quickly adding a new supplier inline.
/// Returns the newly created [Supplier] if successful, or null if cancelled.
class AddSupplierDialog extends StatefulWidget {
  final String warehouseId;

  const AddSupplierDialog({super.key, required this.warehouseId});

  /// Convenience helper to show the dialog and return the created supplier.
  static Future<Supplier?> show(BuildContext context, String warehouseId) {
    return showDialog<Supplier>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddSupplierDialog(warehouseId: warehouseId),
    );
  }

  @override
  State<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supplier = Supplier(
        id: 'sup-${const Uuid().v4().substring(0, 6)}',
        warehouseId: widget.warehouseId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        balanceRemaining:
            double.tryParse(_balanceController.text.trim()) ?? 0.0,
        createdAt: DateTime.now(),
      );

      final created = await getIt.supplierRepository.addSupplier(supplier);

      if (mounted) Navigator.of(context).pop(created);
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

  InputDecoration _decoration({required String label, required IconData icon}) {
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
        color: Theme.of(context).colorScheme.primary,
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
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: theme.colorScheme.primary,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Add Supplier',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                TextFormField(
                  controller: _nameController,
                  decoration: _decoration(
                    label: 'Supplier Name *',
                    icon: Icons.business_rounded,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  decoration: _decoration(
                    label: 'Mobile Number *',
                    icon: Icons.phone_rounded,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _balanceController,
                  decoration: _decoration(
                    label: 'Balance Remaining (â‚¹)',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      if (double.tryParse(v.trim()) == null) {
                        return 'Invalid balance';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _SaveSupplierButton(
                        color: theme.colorScheme.primary,
                        isSaving: _isSaving,
                        onTap: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Gradient confirm button with press feedback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SaveSupplierButton extends StatefulWidget {
  final Color color;
  final bool isSaving;
  final VoidCallback onTap;

  const _SaveSupplierButton({
    required this.color,
    required this.isSaving,
    required this.onTap,
  });

  @override
  State<_SaveSupplierButton> createState() => _SaveSupplierButtonState();
}

class _SaveSupplierButtonState extends State<_SaveSupplierButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isSaving;

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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color.withValues(alpha: 0.88), widget.color],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _pressed ? 0.2 : 0.35),
                blurRadius: _pressed ? 10 : 16,
                offset: Offset(0, _pressed ? 4 : 8),
              ),
            ],
          ),
          child: Center(
            child: widget.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Add Supplier',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
