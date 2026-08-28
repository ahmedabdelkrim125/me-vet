import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_color_scheme_extension.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive_extension.dart';
import 'app_exception.dart';

/// آخر توست ظاهر على الشاشة (لو موجود) — عشان لو حصل خطأ جديد ولسه القديم
/// ظاهر، نقفل القديم بدل ما يتكدسوا فوق بعض.
_AppToastState? _currentToast;

/// يعرض رسالة خطأ بشكل موحّد ومودرن (توست عائم من فوق) في أي شاشة بالتطبيق.
///
/// بيقبل أي error خام زي ما هو — الدالة بتنادي [mapErrorToAppException]
/// تلقائيًا وتطلّع الرسالة العربية المناسبة، فمش لازم تحوّلها بنفسك.
///
/// الاستخدام:
/// ```dart
/// try {
///   await CustomersRepository.instance.addCustomer(customer);
/// } catch (e) {
///   if (context.mounted) showAppError(context, e);
/// }
/// ```
void showAppError(BuildContext context, Object error) {
  final appException = mapErrorToAppException(error);
  _showToast(context, message: appException.message, type: _ToastType.error);
}

/// نفس شكل [showAppError] بالظبط (توست من فوق) بس للنجاح — لون أخضر
/// وأيقونة صح، عشان يبقى واضح للمستخدم إن الحفظ حصل فعليًا.
void showAppSuccess(BuildContext context, String message) {
  _showToast(context, message: message, type: _ToastType.success);
}

enum _ToastType { success, error }

void _showToast(
  BuildContext context, {
  required String message,
  required _ToastType type,
}) {
  // لو فيه توست ظاهر بالفعل، اقفله فورًا قبل ما نطلّع الجديد.
  _currentToast?._dismiss(immediate: true);

  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _AppToast(
      message: message,
      type: type,
      onRegister: (state) => _currentToast = state,
      onDismissed: () {
        entry.remove();
      },
    ),
  );

  overlay.insert(entry);
}

class _AppToast extends StatefulWidget {
  final String message;
  final _ToastType type;
  final ValueChanged<_AppToastState> onRegister;
  final VoidCallback onDismissed;

  const _AppToast({
    required this.message,
    required this.type,
    required this.onRegister,
    required this.onDismissed,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;
  Timer? _autoDismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    widget.onRegister(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _offset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    _autoDismissTimer = Timer(const Duration(seconds: 4), () => _dismiss());
  }

  Future<void> _dismiss({bool immediate = false}) async {
    if (_isDismissing) return;
    _isDismissing = true;
    _autoDismissTimer?.cancel();

    if (immediate || !mounted) {
      widget.onDismissed();
      return;
    }
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    if (identical(_currentToast, this)) _currentToast = null;
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isError = widget.type == _ToastType.error;
    final accent = isError
        ? const Color(0xFFE0473F) // نفس statusNotReached لكن ثابتة هنا
        : colors.primary;
    final icon = isError ? Icons.error_rounded : Icons.check_circle_rounded;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10.h,
      left: 16.w,
      right: 16.w,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _dismiss(),
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < -150) _dismiss();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34.w,
                      height: 34.w,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accent, size: 19),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 7.h),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.cairoMedium16
                              .copyWith(color: colors.text, fontSize: 13.sp),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 7.h, right: 4.w),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
