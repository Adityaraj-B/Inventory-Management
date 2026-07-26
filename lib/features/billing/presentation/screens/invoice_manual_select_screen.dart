import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/core/widgets/search_bar_widget.dart';
import 'package:vishnu_enterprises/data/models/product.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/billing/bloc/cart_item.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_bloc.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_event.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_state.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_bloc.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_event.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_state.dart';

class InvoiceManualSelectScreen extends StatefulWidget {
  const InvoiceManualSelectScreen({super.key});

  @override
  State<InvoiceManualSelectScreen> createState() =>
      _InvoiceManualSelectScreenState();
}

class _InvoiceManualSelectScreenState extends State<InvoiceManualSelectScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final warehouseId = authState is AuthAuthenticated
        ? authState.user.warehouseId
        : null;
    context.read<StockBloc>().add(StockLoadRequested(warehouseId: warehouseId));
  }

  void _showAddProductDialog(Product product) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    if (user == null) return;

    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(
      text: product.unitPrice.toStringAsFixed(2),
    );
    SellMode sellMode = SellMode.piece;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Available: ${product.quantityInStock} units | MRP: ₹${product.mrp}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // Sell Mode Segment
                  Row(
                    children: [
                      const Text(
                        'Sell Mode: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Piece'),
                        selected: sellMode == SellMode.piece,
                        onSelected: (val) {
                          if (val)
                            setModalState(() => sellMode = SellMode.piece);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          'Inner Box (${product.unitsPerBarcode} pcs)',
                        ),
                        selected: sellMode == SellMode.innerBox,
                        onSelected: (val) {
                          if (val)
                            setModalState(() => sellMode = SellMode.innerBox);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: sellMode == SellMode.innerBox
                                ? 'Boxes'
                                : 'Quantity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Unit Rate (₹)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      final qty = int.tryParse(qtyCtrl.text) ?? 1;
                      final price =
                          double.tryParse(priceCtrl.text) ?? product.unitPrice;

                      context.read<InvoiceCreationBloc>().add(
                        AddProductToCart(
                          product: product,
                          quantity: qty,
                          sellMode: sellMode,
                          unitPrice: price,
                          currentUser: user,
                        ),
                      );
                      Navigator.pop(modalContext);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Products')),
      body: BlocConsumer<InvoiceCreationBloc, InvoiceCreationState>(
        listener: (context, state) {
          if (state is InvoiceCartState && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, cartState) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SearchBarWidget(
                  hintText: 'Search products...',
                  onChanged: (q) {
                    final authState = context.read<AuthBloc>().state;
                    final whId = authState is AuthAuthenticated
                        ? authState.user.warehouseId
                        : null;
                    context.read<StockBloc>().add(
                      StockSearchChanged(q, warehouseId: whId),
                    );
                  },
                ),
              ),
              Expanded(
                child: BlocBuilder<StockBloc, StockState>(
                  builder: (context, state) {
                    if (state is StockLoaded) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: state.products.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = state.products[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'SKU: ${product.sku} | Stock: ${product.quantityInStock} pcs | MRP: ₹${product.mrp}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  CupertinoIcons.add_circled_solid,
                                  size: 28,
                                ),
                                color: theme.colorScheme.primary,
                                onPressed: () => _showAddProductDialog(product),
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              if (cartState.cartItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: () => context.push(RoutePaths.billingReview),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Proceed to Review (${cartState.cartItems.length} items)',
                          ),
                          Text(Formatters.currency(cartState.subtotal)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
