import 'package:flutter/material.dart';
import 'package:nyc_public_space_map/about_drawer.dart';
import 'package:nyc_public_space_map/report_issue_drawer.dart';

class SideDrawer extends StatelessWidget {
  final String drawerType;

  const SideDrawer({required this.drawerType, super.key});

  @override
  Widget build(BuildContext context) {
    switch (drawerType) {
      case 'report':
        return const ReportIssueDrawer();
      case 'about':
      default:
        return const AboutDrawer();
    }
  }
}