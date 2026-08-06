import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import '../../../domain/models/customer_status.dart';

Color customerStatusColor(CustomerStatus status) {
  switch (status) {
    case CustomerStatus.active:
      return AppColors.primaryGreen;
    case CustomerStatus.needsFollowUp:
      return AppColors.statOrange;
    case CustomerStatus.stalled:
      return AppColors.statusNotReached;
  }
}
