import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SidebarDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SidebarDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _NavItem(icon: Icons.home, label: 'হোম', index: 0),
      _NavItem(icon: Icons.grid_view_outlined, label: 'টুলস', index: 1),
      _NavItem(icon: Icons.search_outlined, label: 'খুঁজুন', index: 2),
      _NavItem(icon: Icons.layers_outlined, label: 'ট্যাব', index: 3),
      _NavItem(icon: Icons.work_outline, label: 'কাজ দিন', index: 4),
      _NavItem(icon: Icons.person_outline, label: 'প্রোফাইল', index: 5),
    ];

    return Container(
      width: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // App Logo / Icon Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.landscape,
              color: AppColors.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: navItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final item = navItems[idx];
                final isSelected = selectedIndex == item.index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: InkWell(
                    onTap: () => onItemSelected(item.index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0F3E2E) // Dark emerald green
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
