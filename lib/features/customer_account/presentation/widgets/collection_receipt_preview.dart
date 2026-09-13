import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:gal/gal.dart';
import '../../domain/entities/collection_receipt.dart' as domain;
import '../utils/collection_receipt_image.dart';
import 'collection_receipt.dart' as receipt_widget;

Future<void> showCollectionReceiptPreview(
  BuildContext context,
  domain.CollectionReceipt receipt,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CollectionReceiptPreview(receipt: receipt),
  );
}

class CollectionReceiptPreview extends StatefulWidget {
  final domain.CollectionReceipt receipt;

  const CollectionReceiptPreview({super.key, required this.receipt});

  @override
  State<CollectionReceiptPreview> createState() =>
      _CollectionReceiptPreviewState();
}

class _CollectionReceiptPreviewState extends State<CollectionReceiptPreview> {
  final _boundaryKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

  Future<Uint8List> _captureImage() {
    return CollectionReceiptImage.capture(_boundaryKey);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _captureImage();
      await Gal.putImageBytes(
        bytes,
        name: 'collection_receipt_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) showAppSuccess(context, 'تم حفظ الصورة على الجهاز');
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _captureImage();
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          name: 'collection_receipt.png',
          mimeType: 'image/png',
        ),
      ]);
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20.r),
          ),
          padding: EdgeInsets.all(16.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(
                  key: _boundaryKey,
                  child: SizedBox(
                    width: 360,
                    child: receipt_widget.CollectionReceipt(
                      data: widget.receipt,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('حفظ'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSharing ? null : _share,
                        child: _isSharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('مشاركة'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
