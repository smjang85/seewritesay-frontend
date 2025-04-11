import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final List<Widget>? actions;

  const CommonAppBar({
    super.key,
    required this.title,
    this.leadingIcon,
    this.onLeadingTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leadingIcon != null && onLeadingTap != null
          ? IconButton(
        icon: Icon(leadingIcon),
        onPressed: onLeadingTap,
      )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
