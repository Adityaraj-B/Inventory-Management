import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/core/widgets/empty_state.dart';
import 'package:vishnu_enterprises/core/widgets/loading_indicator.dart';
import 'package:vishnu_enterprises/core/widgets/search_bar_widget.dart';
import 'package:vishnu_enterprises/data/models/customer.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_list_bloc.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_list_event.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_list_state.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<CustomerListBloc>().add(const CustomerListLoadRequested());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<CustomerListBloc>().add(CustomerSearchChanged(query));
    });
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
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
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0');
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (modalContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 12,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New Customer',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            CupertinoIcons.xmark,
                            size: 20,
                            color: Colors.black54,
                          ),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    decoration: _buildInputDecoration(
                      'Customer / Business Name',
                      CupertinoIcons.building_2_fill,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          decoration: _buildInputDecoration(
                            'Phone',
                            CupertinoIcons.phone_fill,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          decoration: _buildInputDecoration(
                            'City',
                            CupertinoIcons.location_solid,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    decoration: _buildInputDecoration(
                      'Email Address',
                      CupertinoIcons.mail_solid,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressCtrl,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    decoration: _buildInputDecoration(
                      'Street Address',
                      CupertinoIcons.map_pin_ellipse,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: gstinCtrl,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          decoration: _buildInputDecoration(
                            'GSTIN (Opt)',
                            CupertinoIcons.doc_text_fill,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: balanceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          decoration: _buildInputDecoration(
                            'Balance (â‚¹)',
                            Icons.currency_rupee,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (nameCtrl.text.trim().isEmpty) return;
                          final customer = Customer(
                            id: 'cust-${const Uuid().v4().substring(0, 6)}',
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            gstin: gstinCtrl.text.trim().isEmpty
                                ? null
                                : gstinCtrl.text.trim(),
                            previousBalance:
                                double.tryParse(balanceCtrl.text) ?? 0.0,
                          );
                          context.read<CustomerListBloc>().add(
                            AddCustomerRequested(customer),
                          );
                          Navigator.pop(modalContext);
                        },
                        child: const Center(
                          child: Text(
                            'Add Customer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F6F8),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: const Text(
            'Directory',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 100),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: null,
            elevation: 0,
            backgroundColor: Colors.transparent,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddCustomerDialog();
            },
            icon: const Icon(
              CupertinoIcons.person_add_solid,
              size: 20,
              color: Colors.white,
            ),
            label: const Text(
              'New Customer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SearchBarWidget(
                  hintText: 'Search by name, phone or city...',
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
            Expanded(
              child: BlocConsumer<CustomerListBloc, CustomerListState>(
                listener: (context, state) {
                  if (state is CustomerOperationSuccess) {
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
                  }
                },
                builder: (context, state) {
                  if (state is CustomerListLoading) {
                    return const Center(
                      child: LoadingIndicator(message: 'Loading directory...'),
                    );
                  }

                  if (state is CustomerListError) {
                    return EmptyState(
                      title: 'Failed to load customers',
                      message: state.message,
                      icon: CupertinoIcons.exclamationmark_triangle_fill,
                      action: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => context.read<CustomerListBloc>().add(
                          const CustomerListLoadRequested(),
                        ),
                        child: const Text('Retry'),
                      ),
                    );
                  }

                  if (state is CustomerListLoaded) {
                    if (state.customers.isEmpty) {
                      return EmptyState(
                        title: state.searchQuery.isEmpty
                            ? 'No customers yet'
                            : 'No matching customers',
                        message: state.searchQuery.isEmpty
                            ? 'Tap "New Customer" to create your first customer account.'
                            : 'Try searching with a different name or phone number.',
                        icon: CupertinoIcons.person_2_fill,
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                      itemCount: state.customers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final customer = state.customers[index];
                        final hasDue = customer.previousBalance > 0;

                        return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey.shade100,
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.push(
                                      RoutePaths.customerDetail,
                                      extra: customer,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                theme.colorScheme.primary
                                                    .withValues(alpha: 0.8),
                                                theme.colorScheme.primary,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              customer.name.isNotEmpty
                                                  ? customer.name[0]
                                                        .toUpperCase()
                                                  : 'C',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customer.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,
                                                  letterSpacing: -0.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    CupertinoIcons.phone_fill,
                                                    size: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      customer.phone,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    CupertinoIcons
                                                        .location_solid,
                                                    size: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      customer.city,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: hasDue
                                                    ? AppColors.errorBackground
                                                    : AppColors
                                                          .successBackground,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: hasDue
                                                      ? AppColors.error
                                                            .withValues(alpha: 0.2)
                                                      : AppColors.success
                                                            .withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: Text(
                                                Formatters.currency(
                                                  customer.previousBalance,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: hasDue
                                                      ? AppColors.error
                                                      : AppColors.success,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                CupertinoIcons.chevron_right,
                                                size: 14,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fade(duration: 400.ms, delay: (index * 50).ms)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 400.ms,
                              curve: Curves.easeOutQuart,
                              delay: (index * 50).ms,
                            );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
