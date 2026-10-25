import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';

/// Shows the temporary password returned when an account is created or a
/// password is reset. It is shown once, so it can be copied and handed over.
Future<void> showTemporaryPassword(
  BuildContext context, {
  required String name,
  required String login,
  required String password,
  bool emailSent = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('New sign-in details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This temporary password is shown only once. They must set a new password at first sign-in.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 14),
          Text(name, style: AppTypography.labelMedium),
          Text('Sign in with: $login', style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          SelectableText(
            password,
            style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 6),
          Text(
            emailSent ? 'Also emailed to them.' : 'Not emailed — please hand it over.',
            style: AppTypography.labelSmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: password)),
          child: const Text('Copy'),
        ),
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
      ],
    ),
  );
}

/// Shows the right message after an ApiClient.send(): queued offline, or
/// the temporary password from the server's reply when there is one.
Future<void> showCreateResult(
  BuildContext context,
  dynamic result, {
  required String name,
  required String login,
  required String successText,
}) async {
  if (result is Map && result['_queued'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Saved on this phone. It will be sent when you are back online.'),
    ));
    return;
  }
  final password = result is Map ? (result['temporaryPassword'] ?? result['data']?['temporaryPassword']) : null;
  if (password is String && password.isNotEmpty) {
    await showTemporaryPassword(
      context,
      name: name,
      login: login,
      password: password,
      emailSent: result['emailSent'] == true,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successText), backgroundColor: AppColors.success),
    );
  }
}
