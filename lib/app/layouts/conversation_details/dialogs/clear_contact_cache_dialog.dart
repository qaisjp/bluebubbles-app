import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> showClearContactCacheDialog(BuildContext context, Chat chat) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final confirmed = await showBBDialog<bool>(
    context: context,
    title: "Clear contact cache?",
    body: "Rebuild cached contacts for this chat from your selected contacts account. "
        "Other chats sharing these contacts will also refresh. "
        "Messages, phone contacts, and custom chat names and avatars will not be deleted.",
    actions: [
      BBDialogAction(
        text: "Cancel",
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
      ),
      BBDialogAction(
        text: "Clear contact cache",
        isDestructive: true,
        color: Theme.of(context).colorScheme.error,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  final progress = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: BBProgressDialog(title: "Rebuilding cached contacts..."),
    ),
  );
  String? error;
  try {
    await ContactsSvcV2.clearContactCache(chat);
  } catch (e, stack) {
    Logger.error('Failed to rebuild contact cache', error: e, trace: stack);
    error = e is StateError ? e.message.toString() : "Could not rebuild cached contacts. Please try again.";
  } finally {
    navigator.pop();
    await progress;
  }
  if (!context.mounted) return;
  if (error != null) {
    showSnackbar("Error", error, type: SnackbarType.error);
  } else {
    showSnackbar("Notice", "Contact cache rebuilt!");
  }
}
