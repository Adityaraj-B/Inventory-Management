import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_bloc.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_event.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_state.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_bloc.dart';
import 'package:vishnu_enterprises/features/stock/bloc/stock_state.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vishnu_enterprises/features/main_layout/bloc/nav_cubit.dart';
import 'package:flutter/services.dart';

class InvoiceScanScreen extends StatefulWidget {
  const InvoiceScanScreen({super.key});

  @override
  State<InvoiceScanScreen> createState() => _InvoiceScanScreenState();
}

class _InvoiceScanScreenState extends State<InvoiceScanScreen> {
  bool _isSimulatingScan = false;
  final TextEditingController _manualBarcodeController =
      TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  DateTime? _lastScanTime;

  @override
  void dispose() {
    _manualBarcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted) return;

    // Throttle scans to once every 2.5 seconds to prevent spam
    if (_lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) <
            const Duration(milliseconds: 2500)) {
      return;
    }

    final stockState = context.read<StockBloc>().state;
    final authState = context.read<AuthBloc>().state;

    if (stockState is StockLoaded && authState is AuthAuthenticated) {
      final barcodes = capture.barcodes;
      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first.rawValue;
        if (barcode != null && barcode.isNotEmpty) {
          _lastScanTime = DateTime.now();

          // Find product by SKU or ID matching the barcode
          final product = stockState.products.cast<dynamic>().firstWhere(
            (p) =>
                p.sku.toLowerCase() == barcode.toLowerCase() || p.id == barcode,
            orElse: () => null,
          );

          if (product != null) {
            context.read<InvoiceCreationBloc>().add(
              AddProductToCart(
                product: product,
                quantity: 1,
                currentUser: authState.user,
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Scanned: ${product.name} (+1 added to cart)'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Product not found for barcode: $barcode'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  void _simulateBarcodeScan(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Entry'),
        content: TextField(
          controller: _manualBarcodeController,
          decoration: const InputDecoration(
            hintText: 'Enter Product Barcode/SKU',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
              final barcode = _manualBarcodeController.text.trim();
              if (barcode.isNotEmpty) {
                // Simulate a barcode detection
                final capture = BarcodeCapture(
                  barcodes: [
                    Barcode(rawValue: barcode, format: BarcodeFormat.code128),
                  ],
                );
                _onDetect(capture);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTabActive = context.watch<NavCubit>().state == 2;
    final isRouteCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    final isCameraActive = isTabActive && isRouteCurrent;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Barcode Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
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
        builder: (context, state) {
          final cartCount = state.cartItems.fold(
            0,
            (sum, i) => sum + i.rawQuantity,
          );

          return Stack(
            children: [
              // Real Camera Scanner - only active when visible
              if (isCameraActive)
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),

              // Scanner Target Overlay
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isSimulatingScan
                                  ? Colors.greenAccent
                                  : theme.colorScheme.primary,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isSimulatingScan)
                                const CircularProgressIndicator(
                                  color: Colors.greenAccent,
                                ),
                            ],
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scaleXY(begin: 0.98, end: 1.02, duration: 1200.ms),
                    const SizedBox(height: 24),
                    const Text(
                      'Align barcode within frame',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _simulateBarcodeScan(context),
                      icon: const Icon(CupertinoIcons.barcode),
                      label: const Text('Simulate Barcode Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Actions Bar
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push(RoutePaths.billingManualSelect),
                      icon: const Icon(CupertinoIcons.search, size: 18),
                      label: const Text('Manual Product Search'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    if (cartCount > 0) ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push(RoutePaths.billingReview),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'View Cart ($cartCount items)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              Formatters.currency(state.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
