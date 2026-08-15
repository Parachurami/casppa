import 'package:flutter/material.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/presentation/admin/pages/admin_assessments_tab.dart';
import 'package:casppa/app/presentation/admin/pages/admin_home_tab.dart';
import 'package:casppa/app/presentation/admin/pages/admin_students_tab.dart';
import 'package:casppa/app/presentation/admin/pages/admin_teachers_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _navItems = [
    (outline: Icons.home_outlined, filled: Icons.home, label: 'Home'),
    (
      outline: Icons.assignment_outlined,
      filled: Icons.assignment,
      label: 'Assessments',
    ),
    (outline: Icons.groups_outlined, filled: Icons.groups, label: 'Students'),
    (outline: Icons.school_outlined, filled: Icons.school, label: 'Teachers'),
  ];

  void _navigateToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminHomeTab(onNavigateToTab: _navigateToTab),
      const AdminAssessmentsTab(),
      const AdminStudentsTab(),
      const AdminTeachersTab(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = index == _index;

                return Expanded(
                  child: InkWell(
                    onTap: () => _navigateToTab(index),
                    borderRadius: BorderRadius.circular(32),
                    child: Tooltip(
                      message: item.label,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.16)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? item.filled : item.outline,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
