import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/presentation/cubit/product_picker_cubit.dart';
import 'package:mivet_app/features/home/presentation/cubit/product_picker_state.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/product_picker_empty_state.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/product_picker_footer.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/product_picker_row.dart';

class ProductPickerContent extends StatelessWidget {
  const ProductPickerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocListener<ProductPickerCubit, ProductPickerState>(
      listenWhen: (previous, current) => current.message != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message!)),
        );
      },
      child: BlocBuilder<ProductPickerCubit, ProductPickerState>(
        builder: (context, state) {
          final visible = state.visibleProducts;

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28.r)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 4.h),
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                color: colors.primary, size: 18.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'منتجات عربيتك',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cairoBold18.copyWith(
                                    color: colors.text, fontSize: 15.sp),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close_rounded,
                                  size: 20.sp, color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                        child: TextField(
                          onChanged: context.read<ProductPickerCubit>().search,
                          style: TextStyle(color: colors.text),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن منتج لمعرفة سعره...',
                            hintStyle: TextStyle(color: colors.textMuted),
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 20.sp, color: colors.textMuted),
                            filled: true,
                            fillColor: colors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12.h, horizontal: 12.w),
                          ),
                        ),
                      ),
                      Expanded(
                        child: visible.isEmpty
                            ? ProductPickerEmptyState(
                                hasStock: state.allProducts.isNotEmpty)
                            : ListView.builder(
                                controller: scrollController,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                                itemCount: visible.length,
                                itemBuilder: (context, index) =>
                                    ProductPickerRow(
                                        product: visible[index], state: state),
                              ),
                      ),
                      ProductPickerFooter(state: state),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
