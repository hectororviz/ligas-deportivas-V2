import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 1024;
}

class Responsive {
  const Responsive._();

  static double _width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) => _width(context) < ResponsiveBreakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final width = _width(context);
    return width >= ResponsiveBreakpoints.mobile && width < ResponsiveBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) => _width(context) >= ResponsiveBreakpoints.tablet;

  static EdgeInsets pagePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 20);
    }
    return const EdgeInsets.all(24);
  }
}
