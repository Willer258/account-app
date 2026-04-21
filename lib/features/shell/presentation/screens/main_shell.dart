import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/pockii_colors.dart';
import '../../../transactions/presentation/widgets/transaction_bottom_sheet.dart';
import '../widgets/app_bottom_nav.dart';

/// Main shell widget providing bottom navigation structure.
///
/// Uses go_router's ShellRoute pattern for persistent navigation.
/// Revolut-inspired dark design with floating FAB on home only.
class MainShell extends ConsumerWidget {
  /// Creates a MainShell.
  const MainShell({required this.child, super.key});

  /// The child widget (current route's screen).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isHome = location == AppRoutes.home;

    return Scaffold(
      backgroundColor: context.pockii.background,
      body: child,
      bottomNavigationBar: const AppBottomNav(),
      floatingActionButton: isHome
          ? Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.revolutBlue, AppColors.revolutBlueDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.revolutBlue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => TransactionBottomSheet.show(context),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.revolutOnDark,
                elevation: 0,
                highlightElevation: 0,
                tooltip: 'Ajouter une transaction',
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
