import 'package:flutter/material.dart';
import 'package:nyc_public_space_map/about_drawer.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:nyc_public_space_map/report_issue_drawer.dart';
// import 'package:nyc_public_space_map/feedback_drawer.dart';

class SideDrawer extends StatelessWidget {
  final String drawerType;
  final PublicSpaceFeature? selectedFeature;
  final VoidCallback onFeedbackTap;

  const SideDrawer({required this.drawerType, this.selectedFeature, required this.onFeedbackTap, super.key});

  @override
  Widget build(BuildContext context) {
    switch (drawerType) {
      case 'report':
        return  ReportIssueDrawer(selectedFeature: selectedFeature);
      // case 'feedback':
      //    return  FeedbackDrawer();
      case 'about':
      default:
        return AboutDrawer(onFeedbackTap: onFeedbackTap);
    }
  }
}