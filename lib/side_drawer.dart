import 'package:flutter/material.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:nyc_public_space_map/report_issue_drawer.dart';
// import 'package:nyc_public_space_map/feedback_drawer.dart';

class SideDrawer extends StatelessWidget {
  final PublicSpaceFeature? selectedFeature;

  const SideDrawer({this.selectedFeature, super.key});

  @override
  Widget build(BuildContext context) {
    return ReportIssueDrawer(selectedFeature: selectedFeature);
  }
}
