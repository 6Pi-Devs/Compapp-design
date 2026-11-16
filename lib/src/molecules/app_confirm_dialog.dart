import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// A dialog that asks the user to confirm or cancel one action.
///
/// It shows a [title], a [message] and two buttons of the same size: a quiet
/// cancel button first and the confirm button after it, as on Material. Every
/// string is a prop. When [destructive] is true the confirm button is the
/// `danger` [AppButton], so the error colors only appear when something is
/// really lost ("Reject all pending invitations?"). Otherwise it is the
/// primary one ("Generate a new personal code?").
///
/// The widget is pure presentation: it calls [onConfirm] or [onCancel] and
/// never closes itself. [show] puts it on screen with `showDialog` and pops
/// the answer with the `Navigator`, so the package depends on no router.
///
/// For assistive technology the dialog is a route named by [title], the title
/// is a heading and the buttons are named by their visible labels. The buttons
/// wrap onto two lines when large text or a long label leaves no room for them
/// side by side, and the dialog grows with its text and scrolls when it is
/// taller than the screen.
class AppConfirmDialog extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.destructive = false,
    super.key,
  }) : assert(title != '', 'The dialog needs a title'),
       assert(confirmLabel != '', 'The confirm button needs a label'),
       assert(cancelLabel != '', 'The cancel button needs a label');

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  /// Called by the confirm button.
  final VoidCallback onConfirm;

  /// Called by the cancel button.
  final VoidCallback onCancel;

  /// Styles the confirm button as destructive.
  final bool destructive;

  /// Shows the dialog above the current route and completes with `true` when
  /// the user confirms, and with `false` when they cancel or dismiss it (a tap
  /// on the barrier or the back gesture).
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        onConfirm: () => _pop(dialogContext, true),
        onCancel: () => _pop(dialogContext, false),
      ),
    );
    return confirmed ?? false;
  }

  static void _pop(BuildContext dialogContext, bool answer) {
    if (ModalRoute.of(dialogContext)?.isCurrent ?? false) {
      Navigator.of(dialogContext).pop(answer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  namesRoute: true,
                  child: Text(
                    title,
                    key: const Key('confirmDialog.title'),
                    style: AppTypography.title.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  key: const Key('confirmDialog.message'),
                  style: AppTypography.body.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppButton(
                        key: const Key('confirmDialog.cancel'),
                        label: cancelLabel,
                        onPressed: onCancel,
                        variant: AppButtonVariant.ghost,
                        size: AppButtonSize.md,
                      ),
                      AppButton(
                        key: const Key('confirmDialog.confirm'),
                        label: confirmLabel,
                        onPressed: onConfirm,
                        variant: destructive
                            ? AppButtonVariant.danger
                            : AppButtonVariant.primary,
                        size: AppButtonSize.md,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
