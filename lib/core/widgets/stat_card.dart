// import 'package:flutter/material.dart';
// import '../theme/app_colors.dart';
// import '../theme/app_text_styles.dart';

// /// كارت إحصائية صغير (زي كروت الـ KPI في الهوم)
// class StatCard extends StatelessWidget {
//   final String label;
//   final String value;
//   final String? sub;
//   final Color accent;
//   final IconData icon;

//   const StatCard({
//     super.key,
//     required this.label,
//     required this.value,
//     required this.icon,
//     this.sub,
//     this.accent = AppColors.teal,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border(right: BorderSide(color: accent, width: 4)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 16, color: accent),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Text(
//                   label,
//                   style: AppTextStyles.label,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(value, style: AppTextStyles.statValue),
//           if (sub != null) ...[
//             const SizedBox(height: 2),
//             Text(sub!, style: AppTextStyles.bodySmall),
//           ],
//         ],
//       ),
//     );
//   }
// }
