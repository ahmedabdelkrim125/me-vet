import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class RepAvatarPreset {
  final IconData icon;
  final Color color;
  const RepAvatarPreset(this.icon, this.color);
}

/// Shared avatar presets. Index into this list is what gets persisted on
/// [RepProfileModel.avatarIndex], so saved-rep cards and the picker always
/// agree on what a given rep looks like.
const List<RepAvatarPreset> kRepAvatarPresets = [
  RepAvatarPreset(CupertinoIcons.person_alt_circle_fill, AppColors.primary),
  RepAvatarPreset(
      CupertinoIcons.person_crop_circle_fill, AppColors.primaryGreen),
  RepAvatarPreset(CupertinoIcons.person_circle_fill, AppColors.statBlue),
  RepAvatarPreset(CupertinoIcons.person_2_fill, AppColors.statOrange),
  RepAvatarPreset(CupertinoIcons.person_alt_circle, AppColors.secondary),
  RepAvatarPreset(
      CupertinoIcons.person_crop_circle, AppColors.primaryGreenDark),
];

class RepAvatarPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const RepAvatarPicker({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: List.generate(kRepAvatarPresets.length, (i) {
        final preset = kRepAvatarPresets[i];
        final selected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: preset.color.withOpacity(selected ? 1 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? preset.color : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Icon(
              preset.icon,
              size: 26.sp,
              color: selected ? Colors.white : preset.color,
            ),
          ),
        );
      }),
    );
  }
}

/// Renders a single persisted avatar (used on saved-rep cards).
class RepAvatarView extends StatelessWidget {
  final int avatarIndex;
  final double size;

  const RepAvatarView({super.key, required this.avatarIndex, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final preset = kRepAvatarPresets[avatarIndex % kRepAvatarPresets.length];
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(color: preset.color, shape: BoxShape.circle),
      child: Icon(preset.icon, size: (size * 0.5).sp, color: Colors.white),
    );
  }
}
