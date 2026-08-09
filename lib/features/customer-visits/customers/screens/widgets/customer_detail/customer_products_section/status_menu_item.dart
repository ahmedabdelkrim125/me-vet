import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../../domain/models/customer_status.dart';
import '../../customers_list_view/customer_status_style.dart';

PopupMenuEntry<CustomerStatus> statusMenuItem(
  BuildContext context,
  CustomerStatus status,
  CustomerStatus currentStatus,
) {
  return PopupMenuItem<CustomerStatus>(
    value: status,
    child: Row(
      children: [
        if (status == currentStatus)
          HugeIcon(
            icon: HugeIcons.strokeRoundedTick01,
            color: customerStatusColor(context, status),
            size: 18.sp,
          )
        else
          SizedBox(width: 18.sp),
        SizedBox(width: 8.w),
        Text(status.label),
      ],
    ),
  );
}
