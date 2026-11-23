import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/core/theme/app_theme.dart';
import 'package:bdland_pro/core/constants/app_colors.dart';

void main() {
  test('AppTheme loads successfully with Material 3 and custom card theme', () {
    final theme = AppTheme.lightTheme;
    expect(theme, isNotNull);
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, equals(AppColors.primaryGreen));
    expect(theme.cardTheme, isNotNull);
  });
}
