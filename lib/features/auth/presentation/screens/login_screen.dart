import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vishnu_enterprises/core/constants.dart';
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/data/models/warehouse.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_event.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/injection.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController(text: 'admin@vishnu.com');
  final _passwordController = TextEditingController(text: 'password123');
  String _selectedRole = AppConstants.roleAdmin;
  String? _selectedWarehouseId;
  List<Warehouse> _warehouses = [];
  bool _isLoadingWarehouses = true;
  bool _obscurePassword = true;
  bool _isPressed = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    try {
      final list = await getIt.warehouseRepository.getWarehouses(
        activeOnly: true,
      );
      if (mounted) {
        setState(() {
          _warehouses = list;
          _isLoadingWarehouses = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingWarehouses = false);
      }
    }
  }

  void _onRoleChanged(String newRole) {
    if (newRole == _selectedRole) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRole = newRole;
      if (newRole == AppConstants.roleBillingStaff) {
        _emailController.text = 'billing@vishnu.com';
        if (_selectedWarehouseId == null && _warehouses.isNotEmpty) {
          _selectedWarehouseId = _warehouses.first.id;
        }
      } else {
        _emailController.text = 'admin@vishnu.com';
        _selectedWarehouseId = null;
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    Widget? suffixIcon,
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
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 4, right: 4),
        child: Icon(icon, size: 19, color: Colors.grey.shade400),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
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
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              if (state.user.isAdmin) {
                context.go(RoutePaths.home);
              } else if (state.user.isBillingStaff) {
                context.go(RoutePaths.billingStaffHome);
              } else {
                context.go(RoutePaths.accessDenied);
              }
            } else if (state is AuthError) {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_circle_fill,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.message,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  elevation: 6,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final isAdmin = _selectedRole == AppConstants.roleAdmin;

            return Stack(
              children: [
                // Soft decorative background glow â€” purely cosmetic, keeps the same neutral canvas.
                Positioned(
                  top: -120,
                  right: -80,
                  child: _BackgroundGlow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    size: 320,
                  ),
                ),
                Positioned(
                  bottom: -140,
                  left: -100,
                  child: _BackgroundGlow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    size: 360,
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 40.0,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 40,
                                        offset: const Offset(0, 20),
                                      ),
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.08),
                                        blurRadius: 24,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 20,
                                        sigmaY: 20,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          32,
                                          36,
                                          32,
                                          32,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(alpha: 0.97),
                                              Colors.white.withValues(alpha: 0.85),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            32,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 
                                              0.9,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 84,
                                              height: 84,
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.15),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      theme.colorScheme.primary
                                                          .withValues(alpha: 0.85),
                                                      theme.colorScheme.primary,
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: theme
                                                          .colorScheme
                                                          .primary
                                                          .withValues(alpha: 0.35),
                                                      blurRadius: 24,
                                                      offset: const Offset(
                                                        0,
                                                        10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    CupertinoIcons
                                                        .building_2_fill,
                                                    size: 34,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 22),
                                            Text(
                                              AppConstants.appName,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 27,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black87,
                                                letterSpacing: -0.6,
                                                height: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.07),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'ENTERPRISE INVENTORY & MANAGEMENT',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      theme.colorScheme.primary,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 32),

                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: LayoutBuilder(
                                                builder: (context, constraints) {
                                                  final tabWidth =
                                                      constraints.maxWidth / 2;
                                                  return Stack(
                                                    children: [
                                                      AnimatedAlign(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 280,
                                                            ),
                                                        curve:
                                                            Curves.easeOutCubic,
                                                        alignment: isAdmin
                                                            ? Alignment
                                                                  .centerLeft
                                                            : Alignment
                                                                  .centerRight,
                                                        child: Container(
                                                          width: tabWidth,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(alpha: 
                                                                      0.06,
                                                                    ),
                                                                blurRadius: 10,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      3,
                                                                    ),
                                                              ),
                                                              BoxShadow(
                                                                color: theme
                                                                    .colorScheme
                                                                    .primary
                                                                    .withValues(alpha: 
                                                                      0.06,
                                                                    ),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      1,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: _RoleTabButton(
                                                              title:
                                                                  'Admin Access',
                                                              icon: CupertinoIcons
                                                                  .shield_fill,
                                                              isSelected:
                                                                  isAdmin,
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary,
                                                              onTap: () =>
                                                                  _onRoleChanged(
                                                                    AppConstants
                                                                        .roleAdmin,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: _RoleTabButton(
                                                              title:
                                                                  'Billing Staff',
                                                              icon: CupertinoIcons
                                                                  .doc_text_fill,
                                                              isSelected:
                                                                  _selectedRole ==
                                                                  AppConstants
                                                                      .roleBillingStaff,
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary,
                                                              onTap: () =>
                                                                  _onRoleChanged(
                                                                    AppConstants
                                                                        .roleBillingStaff,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 24),

                                            TextField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              style: const TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              decoration: _buildInputDecoration(
                                                context,
                                                label: 'Email Address',
                                                icon: CupertinoIcons.mail_solid,
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            TextField(
                                              controller: _passwordController,
                                              obscureText: _obscurePassword,
                                              style: const TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              decoration: _buildInputDecoration(
                                                context,
                                                label: 'Password',
                                                icon: CupertinoIcons.lock_fill,
                                                suffixIcon: IconButton(
                                                  splashRadius: 20,
                                                  icon: Icon(
                                                    _obscurePassword
                                                        ? CupertinoIcons
                                                              .eye_slash_fill
                                                        : CupertinoIcons
                                                              .eye_fill,
                                                    size: 18,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _obscurePassword =
                                                        !_obscurePassword,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            AnimatedSize(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeInOutCubic,
                                              child: !isAdmin
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 8.0,
                                                          ),
                                                      child: DropdownButtonFormField<String?>(
                                                        isExpanded: true,
                                                        initialValue:
                                                            _selectedWarehouseId ??
                                                            (_warehouses
                                                                    .isNotEmpty
                                                                ? _warehouses
                                                                      .first
                                                                      .id
                                                                : null),
                                                        style: const TextStyle(
                                                          fontSize: 14.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black87,
                                                        ),
                                                        dropdownColor:
                                                            Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              18,
                                                            ),
                                                        icon: Icon(
                                                          CupertinoIcons
                                                              .chevron_down,
                                                          size: 17,
                                                          color: Colors
                                                              .grey
                                                              .shade400,
                                                        ),
                                                        decoration: _buildInputDecoration(
                                                          context,
                                                          label:
                                                              'Assigned Warehouse (Required)',
                                                          icon: CupertinoIcons
                                                              .house_alt_fill,
                                                        ),
                                                        items: [
                                                          ..._warehouses.map(
                                                            (w) =>
                                                                DropdownMenuItem<
                                                                  String?
                                                                >(
                                                                  value: w.id,
                                                                  child: Text(
                                                                    w.name,
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                        onChanged: (val) {
                                                          setState(() {
                                                            _selectedWarehouseId =
                                                                val;
                                                          });
                                                        },
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                            const SizedBox(height: 24),

                                            GestureDetector(
                                              onTapDown: (_) => setState(
                                                () => _isPressed = true,
                                              ),
                                              onTapUp: (_) => setState(
                                                () => _isPressed = false,
                                              ),
                                              onTapCancel: () => setState(
                                                () => _isPressed = false,
                                              ),
                                              child: AnimatedScale(
                                                scale: _isPressed ? 0.98 : 1.0,
                                                duration: const Duration(
                                                  milliseconds: 120,
                                                ),
                                                curve: Curves.easeOut,
                                                child: Container(
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        theme
                                                            .colorScheme
                                                            .primary
                                                            .withValues(alpha: 0.88),
                                                        theme
                                                            .colorScheme
                                                            .primary,
                                                      ],
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme
                                                            .colorScheme
                                                            .primary
                                                            .withValues(alpha: 
                                                              _isPressed
                                                                  ? 0.2
                                                                  : 0.38,
                                                            ),
                                                        blurRadius: _isPressed
                                                            ? 10
                                                            : 18,
                                                        offset: Offset(
                                                          0,
                                                          _isPressed ? 4 : 9,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18,
                                                          ),
                                                      onTap:
                                                          isLoading ||
                                                              (!isAdmin &&
                                                                  _selectedWarehouseId ==
                                                                      null &&
                                                                  !_isLoadingWarehouses)
                                                          ? null
                                                          : () {
                                                              HapticFeedback.lightImpact();
                                                              final targetWarehouseId =
                                                                  isAdmin
                                                                  ? _selectedWarehouseId
                                                                  : (_selectedWarehouseId ??
                                                                        (_warehouses.isNotEmpty
                                                                            ? _warehouses.first.id
                                                                            : null));

                                                              context.read<AuthBloc>().add(
                                                                AuthLoginRequested(
                                                                  email:
                                                                      _emailController
                                                                          .text
                                                                          .trim(),
                                                                  password:
                                                                      _passwordController
                                                                          .text
                                                                          .trim(),
                                                                  role:
                                                                      _selectedRole,
                                                                  linkedWarehouseId:
                                                                      targetWarehouseId,
                                                                ),
                                                              );
                                                            },
                                                      child: Center(
                                                        child: isLoading
                                                            ? const SizedBox(
                                                                width: 24,
                                                                height: 24,
                                                                child: CircularProgressIndicator(
                                                                  color: Colors
                                                                      .white,
                                                                  strokeWidth:
                                                                      2.5,
                                                                ),
                                                              )
                                                            : Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    'Sign In as ${isAdmin ? 'Admin' : 'Billing Staff'}',
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      letterSpacing:
                                                                          -0.3,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  const Icon(
                                                                    CupertinoIcons
                                                                        .arrow_right,
                                                                    size: 16,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ],
                                                              ),
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _BackgroundGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _RoleTabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleTabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isSelected ? 1 : 0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) {
                return Transform.scale(
                  scale: 1.0 + (0.12 * t),
                  child: Icon(
                    icon,
                    size: 16,
                    color: Color.lerp(Colors.grey.shade500, color, t),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.black87 : Colors.grey.shade500,
                  letterSpacing: -0.2,
                ),
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
