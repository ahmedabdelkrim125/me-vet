import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import '../../../domain/models/customer_status.dart';

Color customerStatusColor(BuildContext context, CustomerStatus status) {
  switch (status) {
    case CustomerStatus.active:
      return context.colors.primary;
    case CustomerStatus.needsFollowUp:
      return context.colors.statOrange;
    case CustomerStatus.stopped:
      return context.colors.statusNotReached;
  }
}
