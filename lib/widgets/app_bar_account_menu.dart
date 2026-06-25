import 'package:flutter/material.dart';

import 'logout_dialog.dart';
import 'profile_avatar.dart';

class AppBarAccountMenu extends StatelessWidget {
  final String userName;
  final String userRole;
  final VoidCallback? onProfileSelected;

  const AppBarAccountMenu({
    super.key,
    required this.userName,
    required this.userRole,
    this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account menu',
      offset: const Offset(0, 46),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'profile') {
          onProfileSelected?.call();
          return;
        }

        if (value == 'logout') {
          showLogoutDialog(context, {'name': userName, 'role': userRole});
        }
      },
      itemBuilder: (context) => [
        if (onProfileSelected != null)
          const PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Color(0xFF005BAB)),
                SizedBox(width: 10),
                Text('Profile'),
              ],
            ),
          ),
        if (onProfileSelected != null) const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_outlined, color: Colors.red),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 6, 4),
            child: Row(
              children: [
                ProfileAvatar(radius: 15, iconSize: 19),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: Color(0xFF005BAB)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
