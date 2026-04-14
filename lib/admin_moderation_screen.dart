import 'package:flutter/material.dart';

import 'colors.dart';
import 'admin_pending_images_screen.dart';
import 'admin_pending_edits_screen.dart';

class AdminModerationScreen extends StatelessWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.dark,
          title: const Text(
            'Moderate Content',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: AppColors.dark,
            unselectedLabelColor: AppColors.gray,
            indicatorColor: AppColors.green,
            tabs: [
              Tab(text: 'Images'),
              Tab(text: 'Data Edits'),
            ],
          ),
        ),
        body: TabBarView(
          children: const [
            AdminPendingImagesScreen(),
            AdminPendingEditsScreen(),
          ],
        ),
      ),
    );
  }
}
