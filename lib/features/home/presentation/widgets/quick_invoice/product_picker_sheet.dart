import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/home/presentation/cubit/product_picker_cubit.dart';
import 'package:mivet_app/features/home/presentation/models/product_picker_args.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/product_picker_content.dart';

class ProductPickerSheet extends StatelessWidget {
  final ProductPickerArgs args;

  const ProductPickerSheet({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductPickerCubit(args),
      child: const ProductPickerContent(),
    );
  }
}
