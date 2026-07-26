import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/stock/bloc/receive_stock_cubit.dart';
import 'package:vishnu_enterprises/features/stock/presentation/widgets/receive_shipment_modal.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ReceiveStockScanScreen extends StatefulWidget {
  const ReceiveStockScanScreen({super.key});

  @override
  State<ReceiveStockScanScreen> createState() => _ReceiveStockScanScreenState();
}

class _ReceiveStockScanScreenState extends State<ReceiveStockScanScreen> {
  bool _isSimulatingScan = false;
  final TextEditingController _manualBarcodeController =
      TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  DateTime? _lastScanTime;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualBarcodeController.dispose();
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

    // Prevent multiple scans while loading or after finding
    final state = context.read<ReceiveStockCubit>().state;
    if (state is ReceiveStockLoading || state is ReceiveStockShipmentFound) {
      return;
    }

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first.rawValue;
      if (barcode != null && barcode.trim().isNotEmpty) {
        _lastScanTime = DateTime.now();
        context.read<ReceiveStockCubit>().scanShipment(barcode.trim());
      }
    }
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Entry'),
        content: TextField(
          controller: _manualBarcodeController,
          decoration: const InputDecoration(
            hintText: 'Enter Shipment Barcode (e.g. SHP-12345)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final barcode = _manualBarcodeController.text.trim();
              if (barcode.isNotEmpty) {
                context.read<ReceiveStockCubit>().scanShipment(barcode);
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
    final isRouteCurrent = ModalRoute.of(context)?.isCurrent ?? true;

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
          'Receive Stock Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<ReceiveStockCubit, ReceiveStockState>(
        listener: (context, state) {
          if (state is ReceiveStockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ReceiveStockShipmentFound) {
            ReceiveShipmentModal.show(context, state.shipment);
          } else if (state is ReceiveStockSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Real Camera Scanner - only active when visible
              if (isRouteCurrent)
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),

              // Scanner Target Simulation View
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
                              if (_isSimulatingScan ||
                                  state is ReceiveStockLoading)
                                const CircularProgressIndicator(
                                  color: Colors.greenAccent,
                                ),
                            ],
                          ),
                        )
                        .animate(target: _isSimulatingScan ? 1 : 0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                          duration: 200.ms,
                        ),
                    const SizedBox(height: 30),
                    const Text(
                      'Scan Shipment Barcode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showManualEntryDialog,
                      icon: const Icon(CupertinoIcons.keyboard),
                      label: const Text('Manual Entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
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
