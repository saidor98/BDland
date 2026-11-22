import 'package:flutter/material.dart';

class ToolItem {
  final String id;
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badgeText; // 'নতুন', 'PRO'
  final Widget Function(BuildContext) screenBuilder;
  final List<String> keywords;

  const ToolItem({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeText,
    required this.screenBuilder,
    required this.keywords,
  });
}
