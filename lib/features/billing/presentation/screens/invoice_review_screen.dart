import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/data/models/customer.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_bloc.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_event.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_state.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_list_bloc.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_list_event.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_list_state.dart';
import 'package:flutter/services.dart';

class InvoiceReviewScreen extends StatefulWidget {
  const InvoiceReviewScreen({super.key});

  @override
  State<InvoiceReviewScreen> createState() => _InvoiceReviewScreenState();
}

class _InvoiceReviewScreenState extends State<InvoiceReviewScreen> {
  final _paidAmountController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final whId = authState is AuthAuthenticated
        ? authState.user.warehouseId
        : null;
    context.read<CustomerListBloc>().add(
      CustomerListLoadRequested(warehouseId: whId),
    );
  }

  void _showQuickAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick Add Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name*',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Name required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (Opt)'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final regex = RegExp(r'^\+?[0-9]{10,13}$');
                    if (!regex.hasMatch(val.trim())) {
                      return 'Invalid phone (10-13 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: gstinCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'GSTIN (Opt)'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final upper = val.trim().toUpperCase();
                    final regex = RegExp(
                      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[0-9A-Z]{3}$',
                    );
                    if (!regex.hasMatch(upper)) {
                      return 'Invalid 15-char GSTIN format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (formKey.currentState!.validate()) {
                      final customer = Customer(
                        id: 'cust-${const Uuid().v4().substring(0, 6)}',
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        address: '',
                        city: cityCtrl.text.trim(),
                        gstin: gstinCtrl.text.trim().isEmpty
                            ? null
                            : gstinCtrl.text.trim().toUpperCase(),
                        previousBalance: 0.0,
                      );
                      context.read<CustomerListBloc>().add(
                        AddCustomerRequested(customer),
                      );
                      context.read<InvoiceCreationBloc>().add(
                        SelectCustomerForInvoice(customer),
                      );
                      Navigator.pop(modalContext);
                    }
                  },
                  child: const Text('Add & Select Customer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Invoice')),
      body: BlocConsumer<InvoiceCreationBloc, InvoiceCreationState>(
        listener: (context, state) {
          if (state is InvoiceCreationSuccess) {
            context.go(
              RoutePaths.billingGenerated,
              extra: state.generatedInvoice,
            );
          } else if (state is InvoiceCreationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is InvoiceCartState && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is InvoiceCreationSubmitting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer Selector
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _showQuickAddCustomerDialog();
                              },
                              icon: const Icon(CupertinoIcons.add, size: 16),
                              label: const Text('Quick Add'),
                            ),
                          ],
                        ),
                        BlocBuilder<CustomerListBloc, CustomerListState>(
                          builder: (context, custState) {
                            if (custState is CustomerListLoaded) {
                              return DropdownButtonFormField<Customer>(
                                isExpanded: true,
                                initialValue: state.selectedCustomer,
                                hint: const Text('Select Customer'),
                                items: custState.customers.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text('${c.name} (${c.phone})'),
                                  );
                                }).toList(),
                                onChanged: (cust) {
                                  if (cust != null) {
                                    context.read<InvoiceCreationBloc>().add(
                                      SelectCustomerForInvoice(cust),
                                    );
                                  }
                                },
                              );
                            }
                            return const CircularProgressIndicator();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cart Line Items
                const Text(
                  'Line Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = state.cartItems[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          item.product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item.totalUnits} units @ â‚¹${item.rate.toStringAsFixed(2)} / unit',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.currency(item.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.minus_circled),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                if (currentUser != null) {
                                  context.read<InvoiceCreationBloc>().add(
                                    UpdateCartItem(
                                      productId: item.product.id,
                                      quantity: item.rawQuantity - 1,
                                      currentUser: currentUser,
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.add_circled),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                if (currentUser != null) {
                                  context.read<InvoiceCreationBloc>().add(
                                    UpdateCartItem(
                                      productId: item.product.id,
                                      quantity: item.rawQuantity + 1,
                                      currentUser: currentUser,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Discount & Payment
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text(
                              Formatters.currency(state.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Discount Amount (â‚¹)',
                          ),
                          onChanged: (val) {
                            final d = double.tryParse(val) ?? 0.0;
                            context.read<InvoiceCreationBloc>().add(
                              SetInvoiceDiscount(d),
                            );
                          },
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Formatters.currency(state.grandTotal),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: state.paymentMethod,
                          items: const [
                            DropdownMenuItem(
                              value: 'Cash',
                              child: Text('Cash'),
                            ),
                            DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                            DropdownMenuItem(
                              value: 'Card',
                              child: Text('Card'),
                            ),
                            DropdownMenuItem(
                              value: 'Bank Transfer',
                              child: Text('Bank Transfer'),
                            ),
                          ],
                          onChanged: (method) {
                            if (method != null) {
                              context.read<InvoiceCreationBloc>().add(
                                SetPaymentDetails(
                                  paymentMethod: method,
                                  amountPaid: state.amountPaid,
                                ),
                              );
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _paidAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Amount Paid (â‚¹)',
                          ),
                          onChanged: (val) {
                            final p = double.tryParse(val) ?? 0.0;
                            context.read<InvoiceCreationBloc>().add(
                              SetPaymentDetails(
                                paymentMethod: state.paymentMethod,
                                amountPaid: p,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: currentUser == null
                      ? null
                      : () {
                          context.read<InvoiceCreationBloc>().add(
                            GenerateInvoiceRequested(currentUser),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Confirm & Generate Invoice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
