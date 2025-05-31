import 'package:flutter/material.dart';

enum AppBarAction { history, settings, help, share, delete }

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<AppBarAction> actions;
  final Function(AppBarAction)? onActionPressed;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.onActionPressed,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      elevation: 2,
      leading:
          showBackButton
              ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
              : null,
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    List<Widget> actionWidgets = [];

    for (var action in actions) {
      IconData icon;
      String tooltip;

      switch (action) {
        case AppBarAction.history:
          icon = Icons.history;
          tooltip = 'History';
          break;
        case AppBarAction.settings:
          icon = Icons.settings;
          tooltip = 'Settings';
          break;
        case AppBarAction.help:
          icon = Icons.help_outline;
          tooltip = 'Help';
          break;
        case AppBarAction.share:
          icon = Icons.share;
          tooltip = 'Share';
          break;
        case AppBarAction.delete:
          icon = Icons.delete_outline;
          tooltip = 'Delete';
          break;
      }

      actionWidgets.add(
        IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: () {
            if (onActionPressed != null) {
              onActionPressed!(action);
            }
          },
        ),
      );
    }

    return actionWidgets;
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

// Example usage:
// CustomAppBar(
//   title: 'QR Code Generator',
//   actions: [AppBarAction.history, AppBarAction.settings],
//   onActionPressed: (action) {
//     if (action == AppBarAction.history) {
//       // Navigate to history screen
//     } else if (action == AppBarAction.settings) {
//       // Navigate to settings screen
//     }
//   },
// )
