import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_state.dart';

class VehicleSetupForm extends StatefulWidget {
  final String representativeName;

  const VehicleSetupForm({super.key, required this.representativeName});

  @override
  State<VehicleSetupForm> createState() => _VehicleSetupFormState();
}

class _VehicleSetupFormState extends State<VehicleSetupForm> {
  final _plateController = TextEditingController();
  final _driverController = TextEditingController();

  @override
  void dispose() {
    _plateController.dispose();
    _driverController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<VehicleStockCubit>().createVehicle(
          plateNumber: _plateController.text,
          driverName: _driverController.text,
        );
  }

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Container(
            constraints: BoxConstraints(maxWidth: 440.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: context.colors.border),
            ),
            child: BlocBuilder<VehicleStockCubit, VehicleStockState>(
              builder: (context, state) {
                final isSaving =
                    state.status == VehicleStockStatus.loadingAction;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 48.sp, color: context.colors.primary),
                    SizedBox(height: 12.h),
                    Text('مخزون العربية',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cairoBold18.copyWith(
                            color: context.colors.text, fontSize: 18.sp)),
                    SizedBox(height: 4.h),
                    Text('لا توجد عربية مرتبطة بحسابك',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cairoMedium16.copyWith(
                            color: context.colors.textMuted, fontSize: 13.sp)),
                    SizedBox(height: 20.h),
                    _field('رقم العربية', _plateController),
                    SizedBox(height: 12.h),
                    _field('اسم السائق', _driverController),
                    SizedBox(height: 12.h),
                    TextFormField(
                      initialValue: widget.representativeName,
                      enabled: false,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'المندوب'),
                    ),
                    SizedBox(height: 20.h),
                    FilledButton(
                      onPressed: isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h)),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('إنشاء العربية'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

  Widget _field(String label, TextEditingController controller) => TextField(
        controller: controller,
        textAlign: TextAlign.right,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label),
      );
}
