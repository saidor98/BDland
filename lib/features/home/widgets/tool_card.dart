import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/tool_item.dart';

class ToolCard extends StatelessWidget {
  final ToolItem item;
  final bool isPinned;
  final VoidCallback onPinToggle;

  const ToolCard({
    super.key,
    required this.item,
    required this.isPinned,
    required this.onPinToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: item.screenBuilder),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPinned
                  ? AppColors.primaryGreen.withOpacity(0.4)
                  : Colors.grey.shade200,
              width: isPinned ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Icon box & Pin button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.12),
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  InkWell(
                    onTap: onPinToggle,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 20,
                        color: isPinned
                            ? AppColors.secondaryGold
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Bottom row: Badge + Open action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.badgeText == 'নতুন'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.badgeText == 'নতুন' ? '+ নতুন' : 'PRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.badgeText == 'নতুন'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFF57F17),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'খুলুন',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.north_east,
                        size: 13,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
