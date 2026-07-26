import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AccessDeniedView extends StatelessWidget {
  final VoidCallback? onSwitchRole;

  const AccessDeniedView({super.key, this.onSwitchRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                final isBillingStaff = user?.isBillingStaff ?? false;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isBillingStaff
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.errorBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBillingStaff
                            ? CupertinoIcons.lock_shield_fill
                            : CupertinoIcons.lock_fill,
                        size: 44,
                        color: isBillingStaff
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isBillingStaff
                          ? 'Billing Staff Restricted View'
                          : 'Access Denied',
                      style: AppTextStyles.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isBillingStaff
                          ? 'Logged in as Billing Staff (Scoped to Warehouse: ${user?.linkedWarehouseId ?? "Assigned Depot"}).\n\nFull Billing Staff interface is out of scope for this phase. Route guard and role validation enforced.'
                          : 'You do not have Administrator permissions to view this section.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        if (onSwitchRole != null) {
                          onSwitchRole!();
                        }
                      },
                      icon: const Icon(
                        CupertinoIcons.arrow_left_circle_fill,
                        size: 18,
                      ),
                      label: const Text('Sign Out / Switch Role'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
