import 'package:flutter/material.dart';
import 'package:nyc_public_space_map/about_drawer.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:nyc_public_space_map/report_issue_drawer.dart';

class SideDrawer extends StatelessWidget {
  final String drawerType;
  final PublicSpaceFeature? selectedFeature;

  const SideDrawer({required this.drawerType, this.selectedFeature, super.key});

  @override
  Widget build(BuildContext context) {
    switch (drawerType) {
      case 'report':
        return  ReportIssueDrawer(selectedFeature: selectedFeature);
      case 'about':
      default:
        return const AboutDrawer();
    }
  }
}